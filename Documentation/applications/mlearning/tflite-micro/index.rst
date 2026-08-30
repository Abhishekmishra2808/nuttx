==============================================================
``tflite-micro`` TensorFlow Lite for Microcontrollers
==============================================================

`TensorFlow Lite for Microcontrollers
<https://github.com/tensorflow/tflite-micro>`_ (TFLM) is a port of TensorFlow
Lite designed to run machine learning models on microcontrollers and other
devices with only a few kilobytes of memory. It has no operating-system
dependencies, no dynamic memory allocation during inference, and executes
``.tflite`` FlatBuffer models.

The NuttX package (``apps/mlearning/tflite-micro``) downloads and patches a
pinned upstream revision the first time it is built, so an internet connection
is required for the initial build.

Dependencies
============

``TFLITEMICRO`` cannot be selected until the following symbols are enabled
(see ``depends on`` in ``apps/mlearning/tflite-micro/Kconfig``):

* ``SYSTEM_FLATBUFFERS``
* ``MATH_GEMMLOWP``
* ``MATH_KISSFFT``
* ``MATH_RUY``

Configuration
=============

The main options exposed under ``Application Configuration`` ->
``Machine Learning Support`` -> ``TFLiteMicro`` are:

.. code-block:: kconfig

   config TFLITEMICRO
       bool "TFLiteMicro"
       depends on SYSTEM_FLATBUFFERS && MATH_GEMMLOWP && MATH_KISSFFT && MATH_RUY

   config TFLITEMICRO_DEBUG
       bool "Print tflite-micro's debug message"

   config TFLITEMICRO_TOOL
       bool "tflite-micro cmdline tool"

   config TFLITEMICRO_SYSLOG
       bool "tflite-micro syslog backend"

   config TFLITEMICRO_HELLOWORLD
       bool "Enable Tflite-micro hello world example"

``TFLITEMICRO_DEBUG``
  Keep the error strings and print memory-usage / timing information. When
  disabled, error strings are stripped to reduce the flash footprint.

``TFLITEMICRO_TOOL``
  Build the ``tflm`` command line tool (see `The tflm tool`_ below). The
  priority and stack size of the tool are configurable via
  ``TFLITEMICRO_TOOL_PRIORITY`` and ``TFLITEMICRO_TOOL_STACKSIZE``.

``TFLITEMICRO_SYSLOG``
  Route the runtime log through the NuttX ``syslog`` back end instead of
  ``stdout``. ``TFLITEMICRO_SYSLOG_LEVEL`` selects the ``syslog`` level and
  follows the mapping in ``syslog.h`` (``0`` = emergency ... ``7`` = debug).

``TFLITEMICRO_HELLOWORLD``
  Build the upstream "hello world" example, a tiny model that approximates the
  sine function. Its priority and stack size are configurable via
  ``TFLITEMICRO_HELLOWORLD_PRIORITY`` and ``TFLITEMICRO_HELLOWORLD_STACKSIZE``.

Hardware acceleration
=====================

When :doc:`cmsis-nn <../cmsis-nn/index>` (``MLEARNING_CMSIS_NN``) is enabled,
TFLM replaces its reference kernels with the Arm CMSIS-NN optimized kernels on
Cortex-M targets. On targets that provide Arm NEON (``ARM_NEON``), a set of
hand-optimized operators under
``apps/mlearning/tflite-micro/operators/neon`` is compiled in as well.

The tflm tool
=============

Enabling ``TFLITEMICRO_TOOL`` registers a ``tflm`` builtin application that can
load a model and run a single profiled inference, which is useful for
benchmarking operators on real hardware:

.. code-block:: text

   Utility to use tflite micro on nuttx.
   [ -C       ] Compile tflite model into c++ codes.
   [ -E       ] Do once evaluation (for profiling).
   [ -i <str> ] Readable model file path.
   [ -o <str> ] Writable c++ file path.
   [ -p <str> ] Prefix of compiled code.
   [ -a <int> ] Arena size (mempool).
   [ -h       ] Print this message.

For example, to profile a model stored on the file system:

.. code-block:: console

   nsh> tflm -E -i /data/model.tflite -a 16384

The arena size (``-a``, default 8 KiB) is the scratch buffer TFLM uses for
tensors; increase it if interpreter allocation fails for a larger model.

Usage from C++
==============

To run inference from your own application, link against the runtime and drive
the interpreter directly:

.. code-block:: cpp

   #include "tensorflow/lite/micro/micro_interpreter.h"
   #include "tensorflow/lite/micro/micro_mutable_op_resolver.h"

   /* Register only the operators your model uses to save memory. */

   tflite::MicroMutableOpResolver<4> resolver;
   resolver.AddFullyConnected();
   resolver.AddSoftmax();
   resolver.AddReshape();
   resolver.AddQuantize();

   uint8_t arena[16 * 1024];
   tflite::MicroInterpreter interpreter(tflite::GetModel(model_data),
                                        resolver, arena, sizeof(arena));
   interpreter.AllocateTensors();

   /* Fill interpreter.input(0), then: */

   interpreter.Invoke();

   /* Read results from interpreter.output(0). */

.. note::

   The number passed to ``MicroMutableOpResolver`` is the maximum number of
   operator types the model may contain. Registering only the operators you
   need keeps the binary small.
