FROM ros:jazzy-ros-base

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends g++ \
    make \
    git \
    ros-jazzy-desktop \
    ros-jazzy-rmw-cyclonedds-cpp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN apt-get update -y

RUN sed  -i -e 's|^Conflicts: catkin|#Conflicts: catkin|' /var/lib/dpkg/status
RUN apt-get install -f

RUN apt-get download python3-catkin-pkg
RUN apt-get download python3-rospkg
RUN dpkg --force-overwrite -i python3-catkin-pkg*.deb
RUN dpkg --force-overwrite -i python3-rospkg*.deb
RUN apt-get install -f

RUN curl -sSL https://ros.packages.techfak.net/gpg.key -o /etc/apt/keyrings/ros-one-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-one-keyring.gpg] https://ros.packages.techfak.net $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/ros1.list
RUN echo "# deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/ros-one-keyring.gpg] https://ros.packages.techfak.net $(lsb_release -cs) main-dbg" | sudo tee -a /etc/apt/sources.list.d/ros1.list

RUN apt-get update -y && apt-get install python3-rosdep -y

# Define custom rosdep package mapping
RUN echo "yaml https://ros.packages.techfak.net/ros-one.yaml ubuntu" | sudo tee /etc/ros/rosdep/sources.list.d/1-ros-one.list
RUN rosdep update

# Install packages, e.g. ROS desktop
RUN apt-get install ros-one-desktop python3-catkin-tools -y

WORKDIR /root/ros1_ws/src

# Use your computers ssh to build docker
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN git clone https://github.com/KABAM-Robotics/kabam_msgs.git -b main
RUN git clone https://github.com/ros-planning/navigation_msgs.git -b ros1
WORKDIR /root/ros1_ws
RUN unset ROS_DISTRO && unset PYTHONPATH && . "/opt/ros/one/setup.sh" && catkin_make

WORKDIR /home/ros_bridge/src
COPY . ros1_bridge/

WORKDIR /home/ros_bridge/

# Use your computers ssh to build docker
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts

RUN --mount=type=ssh vcs import src < src/ros1_bridge/ros1_bridge.repos --recursive

RUN . "/root/ros1_ws/devel/setup.sh" && . /opt/ros/jazzy/setup.sh && colcon build --parallel-workers 4
RUN sed -i '$isource "/root/ros1_ws/devel/setup.bash"' /ros_entrypoint.sh && sed -i '$isource "/home/ros_bridge/install/setup.bash"' /ros_entrypoint.sh

CMD rosparam load /home/ros_bridge/src/ros1_bridge.yaml && ros2 run ros1_bridge parameter_bridge

# docker build --ssh default -t ros1_bridge .
