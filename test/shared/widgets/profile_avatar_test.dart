import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskati/shared/widgets/profile_avatar.dart';

void main() {
  testWidgets('uses the supplied default avatar when no image is selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProfileAvatar(name: 'Avery')),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/default_avatar.png',
    );
  });

  testWidgets('uses the selected local image instead of the default', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(name: 'Avery', imagePath: r'C:\photos\user.png'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<FileImage>());
  });
}
