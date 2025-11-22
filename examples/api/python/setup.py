from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="awap-sdk",
    version="0.1.0",
    author="Academic Workflow Suite Contributors",
    author_email="info@academic-workflow-suite.example",
    description="Python SDK for Academic Workflow API",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/academic-workflow-suite/python-sdk",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Education",
        "Topic :: Education",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "requests>=2.31.0",
        "pydantic>=2.0.0",
        "typing-extensions>=4.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-asyncio>=0.21.0",
            "black>=23.0.0",
            "mypy>=1.0.0",
            "flake8>=6.0.0",
        ],
    },
)
