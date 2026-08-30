========================
Machine Learning Support
========================

NuttX provides a collection of third-party machine learning runtimes and the
supporting math kernels required to run inference on embedded targets. The
runtimes live in the ``apps/mlearning`` directory of the
`apps <https://github.com/apache/nuttx-apps>`_ repository, while the numerical
building blocks they depend on live in ``apps/math`` and ``apps/system``.

All of the packages below are *inference* engines aimed at deeply embedded and
edge (TinyML) use cases. The framework sources are not vendored into the tree;
each package downloads and patches a pinned upstream release the first time it
is built.

Available runtimes
==================

.. list-table::
   :header-rows: 1
   :widths: 20 20 60

   * - Package
     - ``Kconfig`` symbol
     - Description
   * - :doc:`tflite-micro <tflite-micro/index>`
     - ``TFLITEMICRO``
     - TensorFlow Lite for Microcontrollers, the reference TinyML runtime for
       ``.tflite`` FlatBuffer models.
   * - :doc:`cmsis-nn <cmsis-nn/index>`
     - ``MLEARNING_CMSIS_NN``
     - Arm CMSIS-NN efficient neural-network kernels for Cortex-M, used to
       accelerate TensorFlow Lite for Microcontrollers.
   * - :doc:`cmsis <cmsis/index>`
     - ``CMSIS``
     - Arm CMSIS-DSP and CMSIS-NN libraries from the CMSIS_5 distribution.
   * - :doc:`darknet <darknet/index>`
     - ``DARKNET_YOLO``
     - Darknet "You Only Look Once" (YOLO) real-time object detection.
   * - :doc:`libnnablart <libnnablart/index>`
     - ``NNABLA_RT``
     - Sony Neural Network Libraries C runtime.

Math dependencies
=================

TensorFlow Lite for Microcontrollers cannot be selected until its numerical
dependencies are enabled. These are hosted under :doc:`Math Library Support
</applications/math/index>` and ``apps/system``:

* ``SYSTEM_FLATBUFFERS`` -- FlatBuffers serialization used by the ``.tflite``
  model format.
* ``MATH_GEMMLOWP`` -- low-precision (integer) general matrix multiplication.
* ``MATH_RUY`` -- optimized matrix multiplication back end.
* ``MATH_KISSFFT`` -- Fast Fourier Transform library used by audio/DSP front
  ends.

Trying it out
=============

The ``sim`` board ships a ready-made configuration, ``sim:tflm``, that enables
TensorFlow Lite for Microcontrollers together with all of its dependencies and
the ``tflm`` command line tool. It is the quickest way to experiment with the
machine learning stack on a host machine:

.. code-block:: console

   $ ./tools/configure.sh sim:tflm
   $ make
   $ ./nuttx

.. toctree::
   :glob:
   :maxdepth: 1
   :titlesonly:
   :caption: Contents

   */index*
