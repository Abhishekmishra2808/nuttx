=========================
``cmsis`` CMSIS Libraries
=========================

The Cortex Microcontroller Software Interface Standard (CMSIS) is a
vendor-independent hardware abstraction layer for Arm Cortex processors. This
package (``apps/mlearning/cmsis``) builds the digital signal processing and
neural-network libraries from the
`CMSIS_5 <https://github.com/ARM-software/CMSIS_5>`_ distribution. See the
`CMSIS documentation
<http://arm-software.github.io/CMSIS_5/General/html/index.html>`_ for API
details.

The upstream release is selected by ``CMSIS_VER`` (default ``5.8.0``) and is
downloaded automatically on the first build.

Configuration
=============

.. code-block:: kconfig

   config CMSIS
       bool "CMSIS Libraries"

   config CMSIS_DSP
       bool "CMSIS DSP"
       default y

   config CMSIS_NN
       bool "CMSIS NN"
       default y
       depends on CMSIS_DSP

``CMSIS_DSP``
  Enable CMSIS-DSP, a fast implementation of common digital signal processing
  functions (filters, transforms, matrix and statistics routines). Two extra
  build-time checks can be toggled:

  * ``CMSIS_DSP_ARM_MATH_MATRIX_CHECK`` -- validate the sizes of input and
    output matrices.
  * ``CMSIS_DSP_ARM_MATH_ROUNDING`` -- enable rounding in the support
    functions.

``CMSIS_NN``
  Enable CMSIS-NN, the efficient neural-network kernels. It depends on
  ``CMSIS_DSP``.

.. note::

   For accelerating :doc:`TensorFlow Lite for Microcontrollers
   <../tflite-micro/index>`, prefer the standalone :doc:`cmsis-nn
   <../cmsis-nn/index>` package (``MLEARNING_CMSIS_NN``).
