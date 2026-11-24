//
//  PhotoPickerView.swift
//  Helium UI
//
//  Photo picker wrapper (PHPicker, iOS 14+) plus the on-disk store used to
//  keep the picked picture inside the app container so the HUD can read it.
//

import SwiftUI
import PhotosUI

enum HeliumImageStore {
    static let folderName = "HeliumImages"

    static func directory() -> URL? {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = documents.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func path(for file: String) -> URL? {
        guard !file.isEmpty, let dir = directory() else { return nil }
        return dir.appendingPathComponent(file)
    }

    static func load(_ file: String) -> UIImage? {
        guard let url = path(for: file) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    /// Stores the picture as PNG, downscaled so the container does not blow up.
    static func save(_ image: UIImage) -> String? {
        guard let dir = directory() else { return nil }
        let scaled = downscale(image, maxDimension: 2048)
        guard let data = scaled.pngData() else { return nil }
        let name = UUID().uuidString + ".png"
        do {
            try data.write(to: dir.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }
        let ratio = maxDimension / longest
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    var onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                parent.onPick(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let image = object as? UIImage
                DispatchQueue.main.async {
                    self.parent.onPick(image)
                }
            }
        }
    }
}