"""
Academic Workflow API Python SDK

This SDK provides a convenient Python interface to the Academic Workflow API.
"""

import os
import time
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass

import requests


__version__ = "0.1.0"


@dataclass
class Feedback:
    """TMA feedback structure"""
    summary: str
    strengths: List[str]
    areas_for_improvement: List[str]
    detailed_comments: List[str]


@dataclass
class MarkingResult:
    """TMA marking result"""
    tma_id: str
    student_id: str
    score: float
    grade: str
    feedback: Feedback
    marked_at: str

    @classmethod
    def from_dict(cls, data: dict) -> 'MarkingResult':
        """Create MarkingResult from API response"""
        feedback_data = data.get('feedback', {})
        feedback = Feedback(
            summary=feedback_data.get('summary', ''),
            strengths=feedback_data.get('strengths', []),
            areas_for_improvement=feedback_data.get('areas_for_improvement', []),
            detailed_comments=feedback_data.get('detailed_comments', [])
        )

        return cls(
            tma_id=data['tma_id'],
            student_id=data['student_id'],
            score=data['score'],
            grade=data['grade'],
            feedback=feedback,
            marked_at=data['marked_at']
        )


class AwapError(Exception):
    """Base exception for AWAP SDK"""
    pass


class AwapAPIError(AwapError):
    """API request error"""
    def __init__(self, message: str, status_code: Optional[int] = None):
        super().__init__(message)
        self.status_code = status_code


class AwapTimeoutError(AwapError):
    """Operation timeout error"""
    pass


class AwapClient:
    """Academic Workflow API Client

    Example usage:
        ```python
        from awap_sdk import AwapClient

        client = AwapClient(api_url="http://localhost:8080")

        # Upload and mark a TMA
        result = client.mark_tma(
            file_path="essay.pdf",
            student_id="student001",
            rubric="default"
        )

        print(f"Score: {result.score}")
        print(f"Grade: {result.grade}")
        ```
    """

    def __init__(
        self,
        api_url: Optional[str] = None,
        timeout: int = 300,
        verify_ssl: bool = True
    ):
        """Initialize AWAP Client

        Args:
            api_url: API base URL (defaults to AWS_API_URL env var or localhost)
            timeout: Request timeout in seconds
            verify_ssl: Whether to verify SSL certificates
        """
        self.api_url = api_url or os.getenv('AWS_API_URL', 'http://localhost:8080')
        self.timeout = timeout
        self.session = requests.Session()
        self.session.verify = verify_ssl

    def _request(
        self,
        method: str,
        endpoint: str,
        **kwargs
    ) -> requests.Response:
        """Make API request with error handling"""
        url = f"{self.api_url}{endpoint}"

        try:
            response = self.session.request(method, url, timeout=30, **kwargs)
            response.raise_for_status()
            return response
        except requests.exceptions.HTTPError as e:
            raise AwapAPIError(
                f"API request failed: {e}",
                status_code=e.response.status_code if e.response else None
            )
        except requests.exceptions.RequestException as e:
            raise AwapAPIError(f"Request failed: {e}")

    def upload_tma(
        self,
        file_path: str,
        student_id: str,
        rubric: str = "default"
    ) -> str:
        """Upload a TMA file

        Args:
            file_path: Path to TMA PDF file
            student_id: Student identifier
            rubric: Rubric to use for marking

        Returns:
            TMA ID

        Raises:
            AwapAPIError: If upload fails
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"TMA file not found: {file_path}")

        with open(file_path, 'rb') as f:
            files = {'file': (os.path.basename(file_path), f, 'application/pdf')}
            data = {
                'student_id': student_id,
                'rubric': rubric
            }

            response = self._request(
                'POST',
                '/api/v1/tma/upload',
                files=files,
                data=data
            )

        result = response.json()
        tma_id = result.get('tma_id')

        if not tma_id:
            raise AwapAPIError("No TMA ID returned from upload")

        return tma_id

    def submit_for_marking(
        self,
        tma_id: str,
        rubric: str = "default",
        auto_feedback: bool = True
    ) -> str:
        """Submit TMA for marking

        Args:
            tma_id: TMA identifier
            rubric: Rubric to use
            auto_feedback: Whether to generate automatic feedback

        Returns:
            Job ID

        Raises:
            AwapAPIError: If submission fails
        """
        response = self._request(
            'POST',
            f'/api/v1/tma/{tma_id}/mark',
            json={
                'rubric': rubric,
                'auto_feedback': auto_feedback
            }
        )

        result = response.json()
        job_id = result.get('job_id')

        if not job_id:
            raise AwapAPIError("No job ID returned")

        return job_id

    def get_job_status(self, job_id: str) -> Dict[str, Any]:
        """Get job status

        Args:
            job_id: Job identifier

        Returns:
            Job status information

        Raises:
            AwapAPIError: If request fails
        """
        response = self._request('GET', f'/api/v1/jobs/{job_id}')
        return response.json()

    def get_results(self, tma_id: str) -> MarkingResult:
        """Get marking results

        Args:
            tma_id: TMA identifier

        Returns:
            Marking results

        Raises:
            AwapAPIError: If request fails
        """
        response = self._request('GET', f'/api/v1/tma/{tma_id}/results')
        return MarkingResult.from_dict(response.json())

    def wait_for_completion(
        self,
        job_id: str,
        poll_interval: int = 5,
        timeout: Optional[int] = None
    ) -> str:
        """Wait for job to complete

        Args:
            job_id: Job identifier
            poll_interval: Seconds between status checks
            timeout: Maximum time to wait (uses client timeout if not specified)

        Returns:
            Final job status

        Raises:
            AwapTimeoutError: If timeout exceeded
            AwapAPIError: If job fails
        """
        timeout = timeout or self.timeout
        start_time = time.time()

        while True:
            elapsed = time.time() - start_time
            if elapsed > timeout:
                raise AwapTimeoutError(f"Job did not complete within {timeout} seconds")

            status_data = self.get_job_status(job_id)
            status = status_data.get('status')

            if status == 'completed':
                return status
            elif status == 'failed':
                error = status_data.get('error', 'Unknown error')
                raise AwapAPIError(f"Job failed: {error}")

            time.sleep(poll_interval)

    def mark_tma(
        self,
        file_path: str,
        student_id: str,
        rubric: str = "default",
        wait: bool = True
    ) -> MarkingResult:
        """Upload, mark, and get results for a TMA (convenience method)

        Args:
            file_path: Path to TMA PDF file
            student_id: Student identifier
            rubric: Rubric to use
            wait: Whether to wait for completion

        Returns:
            Marking results

        Raises:
            AwapAPIError: If any step fails
            AwapTimeoutError: If marking times out
        """
        # Upload
        tma_id = self.upload_tma(file_path, student_id, rubric)

        # Submit for marking
        job_id = self.submit_for_marking(tma_id, rubric)

        if not wait:
            # Return partial result
            return MarkingResult(
                tma_id=tma_id,
                student_id=student_id,
                score=0.0,
                grade='',
                feedback=Feedback('', [], [], []),
                marked_at=''
            )

        # Wait for completion
        self.wait_for_completion(job_id)

        # Get results
        return self.get_results(tma_id)


# Convenience exports
__all__ = [
    'AwapClient',
    'AwapError',
    'AwapAPIError',
    'AwapTimeoutError',
    'MarkingResult',
    'Feedback',
]
