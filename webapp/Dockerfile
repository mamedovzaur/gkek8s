# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

RUN apt-get update && apt-get install -y iputils-ping telnet

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Run app.py when the container launches
CMD ["python", "server.py"]