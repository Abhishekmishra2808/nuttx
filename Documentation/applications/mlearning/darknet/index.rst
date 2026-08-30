============================================
``darknet`` YOLO: Real-Time Object Detection
============================================

`Darknet <https://github.com/pjreddie/darknet>`_ is an open source neural
network framework written in C. This package (``apps/mlearning/darknet``)
integrates its "You Only Look Once" (YOLO) real-time object detection system,
a state-of-the-art model that detects and localizes objects in a single
forward pass.

The upstream revision is selected by ``DARKNET_YOLO_VER`` (default
``master``) and is downloaded automatically on the first build, so an internet
connection is required.

.. note::

   YOLO is considerably heavier than the microcontroller-oriented runtimes in
   this menu. It targets application-class devices with substantial RAM and
   compute rather than deeply embedded microcontrollers.

Configuration
=============

.. code-block:: kconfig

   config DARKNET_YOLO
       bool "YOLO: Real-Time Object Detection"
       default n

   config DARKNET_YOLO_VER
       string "DARKNET YOLO version"
       default "master"

Enable ``DARKNET_YOLO`` under ``Application Configuration`` ->
``Machine Learning Support`` to build the library.
