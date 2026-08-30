========================================
``libnnablart`` NNABLA Runtime Libraries
========================================

`nnabla-c-runtime <https://github.com/sony/nnabla-c-runtime>`_ is a runtime
library from Sony for running inference on neural networks created with
`Neural Network Libraries <https://nnabla.org/>`_ (NNabla). It is a small,
portable C implementation intended for embedded deployment of models trained
with NNabla.

This package (``apps/mlearning/libnnablart``) downloads a pinned upstream
release the first time it is built, so an internet connection is required.

Configuration
=============

.. code-block:: kconfig

   config NNABLA_RT
       bool "NNABLA Runtime Libraries"
       default n

   config NNABLA_RT_VER
       string "Default NNABLA Runtime version"
       default "1.24.0"

Enable ``NNABLA_RT`` under ``Application Configuration`` ->
``Machine Learning Support`` to build the runtime. The upstream version is
selected by ``NNABLA_RT_VER``.
