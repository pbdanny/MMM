# Start with a Python base image (Debian-based for broader compatibility)
FROM python:3.11-slim

# Set environment variables for non-interactive installations and locale
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=en_US.UTF-8
ENV TZ=:/etc/localtime

# If deploying to specific environments like AWS Lambda, consider these:
# ENV PATH=/var/lang/bin:/usr/local/bin:/usr/bin/:/bin:/opt/bin
# ENV LD_LIBRARY_PATH=/var/lang/lib:/lib64:/usr/lib64:/var/runtime:/var/runtime/lib:/var/task:/var/task/lib:/opt/lib
# ENV LAMBDA_TASK_ROOT=/var/task
# ENV LAMBDA_RUNTIME_DIR=/var/runtime

# 1. Install System Dependencies:
# Update package lists and install build essentials (compilers for many packages)
# r-base for R language, libcurl4-openssl-dev for many R packages, python3-dev for Python header files
# Remove libatlas-base-dev for new linux version
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    make \
    cmake \
    g++ \
    libcurl4-openssl-dev \
    libpcre2-dev \
    liblzma-dev \
    libbz2-dev \
    libicu-dev \
    libblas-dev \
    liblapack-dev \
    gfortran \
    libopenblas-dev \
    zlib1g-dev \
    libtirpc-dev \
    libdeflate-dev \
    r-base \
    python3-setuptools \
    python3-dev && \
    rm -rf /var/lib/apt/lists/*
    # Optional: Install specific R packages as apt-get binaries if available and beneficial (e.g., for complex system dependencies)

# Upgrade pip for Python package installations
RUN pip3 install --upgrade pip

# Set the working directory inside the container
WORKDIR /app

# 2. Install Python Packages:
# Copy Python requirements file
COPY requirements.txt .
# Install Python packages
RUN pip3 install -r requirements.txt

# 3. Install R Packages:
# Copy R requirements file (e.g., requirements.r)
COPY requirements.r .
# Install R packages by executing the R script
RUN Rscript requirements.r

# 4. Copy your application code
# COPY . /app

# Best Practice: Switch to a non-root user for security
# RUN addgroup --system app && adduser --system --ingroup app app
# RUN chown app:app -R /home/app
# USER app

# # Create a directory for volumns
RUN mkdir -p /app/notebooks /app/output /app/input
RUN chmod 755 /app/notebooks /app/output /app/input

# Expose the port if your application is a web service (e.g., Flask or Shiny app)
# EXPOSE 5000 # For Flask
# EXPOSE 3838 # For Shiny apps
# For Jupyter
EXPOSE 8888

# Define the default command to run your application when the container starts
# Example: Running a Python script that might call R
# CMD ["python3", "./your_main_script.py"]
# Example: Running an R Shiny app (adjust path if using different WORKDIR/COPY
# strategy)
# CMD ["Rscript", "/home/shiny-app/app.R"]

# Start Jupyter
RUN jupyter notebook --generate-config

# Configure Jupyter to allow external connections
RUN echo "c.NotebookApp.ip = '0.0.0.0'" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.port = 8888" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.allow_root = True" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.password = ''" >> /root/.jupyter/jupyter_notebook_config.py

# Start Jupyter Lab by default
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--NotebookApp.password=''"]
