"""
Locust load testing configuration for Academic Workflow Suite
Usage: locust -f locust_config.py --host=http://localhost:8000
"""

from locust import HttpUser, task, between, SequentialTaskSet, events
import json
import random
import string
import time
from datetime import datetime

# Sample TMA content for testing
SAMPLE_TMAS = {
    "short": """
# Question 1
What is the capital of France?

## Answer
Paris is the capital of France.
""",
    "medium": """
# Question 1
Explain the concept of object-oriented programming.

## Answer
Object-oriented programming (OOP) is a programming paradigm based on the concept
of objects, which can contain data and code. The data is in the form of fields
(often known as attributes or properties), and the code is in the form of
procedures (often known as methods).

# Question 2
What are the four pillars of OOP?

## Answer
The four pillars of OOP are:
1. Encapsulation - bundling data and methods
2. Abstraction - hiding complex implementation details
3. Inheritance - creating new classes from existing ones
4. Polymorphism - objects taking multiple forms
""",
    "long": """
# Question 1
Discuss the impact of climate change on global ecosystems.

## Answer
Climate change has profound effects on global ecosystems. Rising temperatures
alter habitats, forcing species to migrate or adapt. Ocean acidification
threatens marine life, particularly coral reefs and shellfish. Changes in
precipitation patterns affect freshwater availability and agricultural
productivity. Extreme weather events become more frequent and severe,
disrupting ecosystems and human communities alike.

[Content continues for several paragraphs...]
""" + "Lorem ipsum dolor sit amet. " * 200
}

def random_student_id():
    """Generate a random student ID"""
    return f"STU{random.randint(10000, 99999)}"

def random_tma_id():
    """Generate a random TMA ID"""
    return f"TMA{random.randint(1000, 9999)}"


class TMAWorkflow(SequentialTaskSet):
    """Sequential task set representing a complete TMA submission workflow"""

    def on_start(self):
        """Initialize user session"""
        self.student_id = random_student_id()
        self.tma_id = None
        self.submission_id = None

    @task
    def submit_tma(self):
        """Submit a TMA for grading"""
        self.tma_id = random_tma_id()
        tma_size = random.choice(["short", "medium", "long"])

        payload = {
            "tma_id": self.tma_id,
            "student_id": self.student_id,
            "content": SAMPLE_TMAS[tma_size],
            "metadata": {
                "course": "CS101",
                "assignment": f"Assignment {random.randint(1, 10)}",
                "submitted_at": datetime.utcnow().isoformat(),
            }
        }

        with self.client.post(
            "/api/v1/tma/submit",
            json=payload,
            catch_response=True,
            name="/api/v1/tma/submit"
        ) as response:
            if response.status_code == 200:
                data = response.json()
                self.submission_id = data.get("submission_id")
                response.success()
            else:
                response.failure(f"Failed to submit TMA: {response.status_code}")

    @task
    def check_status(self):
        """Check submission status"""
        if not self.submission_id:
            return

        with self.client.get(
            f"/api/v1/tma/status/{self.submission_id}",
            catch_response=True,
            name="/api/v1/tma/status"
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to check status: {response.status_code}")

    @task
    def get_feedback(self):
        """Retrieve feedback for submission"""
        if not self.submission_id:
            return

        # Wait a bit to simulate processing time
        time.sleep(random.uniform(0.5, 2.0))

        with self.client.get(
            f"/api/v1/tma/feedback/{self.submission_id}",
            catch_response=True,
            name="/api/v1/tma/feedback"
        ) as response:
            if response.status_code == 200:
                data = response.json()
                if "feedback" in data:
                    response.success()
                else:
                    response.failure("No feedback in response")
            elif response.status_code == 202:
                # Still processing
                response.success()
            else:
                response.failure(f"Failed to get feedback: {response.status_code}")


class TMASubmissionUser(HttpUser):
    """User that submits TMAs and checks feedback"""
    wait_time = between(1, 3)
    tasks = [TMAWorkflow]


class HighLoadUser(HttpUser):
    """User for high-load testing with rapid requests"""
    wait_time = between(0.1, 0.5)

    @task(3)
    def submit_short_tma(self):
        """Submit short TMA (most common)"""
        payload = {
            "tma_id": random_tma_id(),
            "student_id": random_student_id(),
            "content": SAMPLE_TMAS["short"],
            "metadata": {"course": "CS101"}
        }

        self.client.post("/api/v1/tma/submit", json=payload, name="/api/v1/tma/submit [short]")

    @task(2)
    def submit_medium_tma(self):
        """Submit medium TMA"""
        payload = {
            "tma_id": random_tma_id(),
            "student_id": random_student_id(),
            "content": SAMPLE_TMAS["medium"],
            "metadata": {"course": "CS201"}
        }

        self.client.post("/api/v1/tma/submit", json=payload, name="/api/v1/tma/submit [medium]")

    @task(1)
    def submit_long_tma(self):
        """Submit long TMA (least common)"""
        payload = {
            "tma_id": random_tma_id(),
            "student_id": random_student_id(),
            "content": SAMPLE_TMAS["long"],
            "metadata": {"course": "CS301"}
        }

        self.client.post("/api/v1/tma/submit", json=payload, name="/api/v1/tma/submit [long]")

    @task(2)
    def check_random_status(self):
        """Check status of random submission"""
        submission_id = f"sub_{random.randint(1000, 9999)}"
        self.client.get(f"/api/v1/tma/status/{submission_id}", name="/api/v1/tma/status")


class BurstLoadUser(HttpUser):
    """User simulating burst traffic patterns"""
    wait_time = between(5, 15)  # Long wait between bursts

    @task
    def burst_submissions(self):
        """Submit multiple TMAs in quick succession"""
        burst_size = random.randint(3, 10)

        for _ in range(burst_size):
            payload = {
                "tma_id": random_tma_id(),
                "student_id": random_student_id(),
                "content": SAMPLE_TMAS["short"],
                "metadata": {"burst": True}
            }

            self.client.post("/api/v1/tma/submit", json=payload, name="/api/v1/tma/submit [burst]")
            time.sleep(random.uniform(0.1, 0.3))


# Event handlers for custom metrics
@events.init.add_listener
def on_locust_init(environment, **kwargs):
    """Initialize custom metrics tracking"""
    print("Initializing load test...")
    print(f"Target host: {environment.host}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Called when test starts"""
    print("Load test starting...")
    print(f"Users: {environment.runner.target_user_count if hasattr(environment.runner, 'target_user_count') else 'N/A'}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Called when test stops"""
    print("Load test completed!")
    if environment.stats:
        print("\n=== Test Summary ===")
        print(f"Total requests: {environment.stats.total.num_requests}")
        print(f"Total failures: {environment.stats.total.num_failures}")
        print(f"Average response time: {environment.stats.total.avg_response_time:.2f}ms")
        print(f"RPS: {environment.stats.total.current_rps:.2f}")


# Load test profiles (use with --class parameter)
class LightLoad(TMASubmissionUser):
    """Light load: 1-10 concurrent users"""
    wait_time = between(2, 5)


class MediumLoad(TMASubmissionUser):
    """Medium load: 10-50 concurrent users"""
    wait_time = between(1, 3)


class HeavyLoad(HighLoadUser):
    """Heavy load: 50-100+ concurrent users"""
    wait_time = between(0.1, 1)


# Custom shape for sustained load testing
from locust import LoadTestShape

class SustainedLoadTest(LoadTestShape):
    """
    Sustained load test with gradual ramp-up and sustained period
    """

    stages = [
        {"duration": 60, "users": 10, "spawn_rate": 1},   # Warm up
        {"duration": 180, "users": 50, "spawn_rate": 2},  # Ramp to 50
        {"duration": 300, "users": 50, "spawn_rate": 0},  # Sustain 50 for 5 min
        {"duration": 420, "users": 100, "spawn_rate": 2}, # Ramp to 100
        {"duration": 600, "users": 100, "spawn_rate": 0}, # Sustain 100 for 3 min
        {"duration": 660, "users": 0, "spawn_rate": 5},   # Ramp down
    ]

    def tick(self):
        run_time = self.get_run_time()

        for stage in self.stages:
            if run_time < stage["duration"]:
                return (stage["users"], stage["spawn_rate"])

        return None  # Test complete
