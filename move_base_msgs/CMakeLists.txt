cmake_minimum_required(VERSION 3.5)
project(move_base_msgs)

find_package(ament_cmake REQUIRED)

find_package(actionlib_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(rosidl_default_generators REQUIRED)

set(msg_files
  "msg/MoveBaseActionResult.msg"
  "msg/MoveBaseResult.msg"
)

rosidl_generate_interfaces(${PROJECT_NAME}
  ${msg_files}
  DEPENDENCIES actionlib_msgs geometry_msgs
)

ament_export_dependencies(rosidl_default_runtime)

ament_package()
