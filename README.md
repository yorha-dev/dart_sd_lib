# dart_sd_lib

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Status: Alpha](https://img.shields.io/badge/Status-Alpha-yellow)

A **stable-diffusion.cpp** binding for Dart. Run local text-to-image models
directly in your Dart/Flutter applications.

>Status: Experimental / Alpha
>
>This project is under active development. APIs, build configuration,
>and platform support may change. It is not yet recommended for production use.

## Features

- Text-to-Image: Generate images from text prompts.

- Image-to-Image: Use an existing image as the basis for generation.

- Native inference: Delegate model execution to the underlying C++ implementation.

- Flutter integration: Designed to be used in Dart and Flutter projects.

Some capabilities depend on the underlying stable-diffusion.cpp implementation
and the current state of the Dart bindings. Not all upstream features have been
independently validated through this package.

## Reuirements

- CMake
- A compatible C/C++ compiler
- Android NDK for Android builds
- Git

## Installation

On your `pubspec.yaml`, add:

```yaml
dependencies:
  dart_sd_lib:
    git:
      url: https://github.com/yorha-dev/dart_sd_lib.git
```

## Usage

Imporrt package:

```dart
import 'package:dart_sd_lib/dart_sd_lib.dart';
```

Initialize the native context:

```dart
final sd = StableDiffusion(
  modelPath: '/path/to/model.safetensors',
);
```

Generete an image:

```dart
final result = sd.generateImg(
  prompt: 'A futuristic city at sunset',
  negativePrompt: 'low quality, blurry',
  sampleSteps: 20,
  int width = 512,
  int height = 512
);
```

Convert to Image:

```dart
final image = sd.toImage(result.first, 512, 512, 3);
```

The native context should be released when
it is no longer needed:

```dart
sd.dispose();
```

## Known Limitations

As an experimental FFI project, there are areas that still
require development and validation:

- Native memory ownership and resource lifecycle management.
- Error handling between Dart and native code.
- Platform-specific build and runtime validation.
- Automated tests for Dart and native integration.
- API stability and documentation.

## Source Projects and References

- Leejet's [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp.git) project.

## Dependencies

- [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp.git)
- [ffigen](https://pub.dev/packages/ffigen/versions/9.0.1)
- [ffi](https://pub.dev/packages/ffi/versions/2.1.2)
- [image](https://pub.dev/packages/image/versions/4.2.0)

## Licence

This project is licensed under the MIT License - see the `LICENSE` file for details.