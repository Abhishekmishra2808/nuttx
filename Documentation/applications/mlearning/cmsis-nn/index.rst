====================================
``cmsis-nn`` Arm CMSIS-NN Library
====================================

`CMSIS-NN <https://github.com/ARM-software/CMSIS-NN>`_ is a collection of
efficient neural-network kernels developed by Arm to maximize performance and
minimize memory footprint of neural networks on Cortex-M and Cortex-A cores.

This package (``apps/mlearning/cmsis-nn``) integrates the standalone CMSIS-NN
repository. It is primarily used as an acceleration back end for
:doc:`TensorFlow Lite for Microcontrollers <../tflite-micro/index>`: when
``MLEARNING_CMSIS_NN`` is enabled together with ``TFLITEMICRO``, the CMSIS-NN
kernels replace the corresponding TFLM reference kernels on Cortex-M targets.

.. note::

   This is distinct from the :doc:`cmsis <../cmsis/index>` package, which
   provides CMSIS-DSP and CMSIS-NN from the older combined CMSIS_5
   distribution. Use this ``cmsis-nn`` package with TensorFlow Lite for
   Microcontrollers.

Configuration
=============

.. code-block:: kconfig

   config MLEARNING_CMSIS_NN
       bool "CMSIS_NN Library"
       default n

Enable ``MLEARNING_CMSIS_NN`` under ``Application Configuration`` ->
``Machine Learning Support``. On its own it builds the CMSIS-NN kernels; the
acceleration only takes effect for a runtime that dispatches to them, such as
TensorFlow Lite for Microcontrollers.

The upstream revision is pinned in ``apps/mlearning/cmsis-nn/Makefile`` and is
downloaded automatically on the first build, so an internet connection is
required.
