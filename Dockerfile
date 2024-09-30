FROM ros:humble-ros-base-jammy

RUN apt-get -y update && \
    apt-get install -y --no-install-recommends g++ \
    make \
    git \
    ros-humble-desktop \
    ros-humble-rmw-cyclonedds-cpp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


RUN mv /etc/apt/sources.list.d/ros2-latest.list /root/
RUN apt-get update -y

RUN sed  -i -e 's|^Conflicts: catkin|#Conflicts: catkin|' /var/lib/dpkg/status
RUN apt-get install -f

RUN apt-get download python3-catkin-pkg
RUN apt-get download python3-rospkg
RUN apt-get download python3-rosdistro
RUN dpkg --force-overwrite -i python3-catkin-pkg*.deb
RUN dpkg --force-overwrite -i python3-rospkg*.deb
RUN dpkg --force-overwrite -i python3-rosdistro*.deb
RUN apt-get install -f

RUN apt-get update -y && apt-get upgrade -y


RUN apt-get install -y ros-desktop-dev

WORKDIR /home/ros_bridge/src
COPY . .

WORKDIR /home/ros_bridge/

RUN /ros_entrypoint.sh colcon build --parallel-workers 4 && sed -i '$isource "/home/ros_bridge/install/setup.bash"' /ros_entrypoint.sh

CMD rosparam load mighty_bridge.yaml && ros2 run ros1_bridge dynamic_bridge --bridge-all-topics
