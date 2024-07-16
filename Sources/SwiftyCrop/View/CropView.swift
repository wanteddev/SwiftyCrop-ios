import SwiftUI

import Montage

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CropViewModel

    private let image: UIImage
    private let maskShape: MaskShape
    private let configuration: SwiftyCropConfiguration
    private let onComplete: (UIImage?) -> Void

    init(
        image: UIImage,
        maskShape: MaskShape,
        configuration: SwiftyCropConfiguration,
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.image = image
        self.maskShape = maskShape
        self.configuration = configuration
        self.onComplete = onComplete
        _viewModel = StateObject(
            wrappedValue: CropViewModel(
                maskRadius: configuration.maskRadius,
                maxMagnificationScale: configuration.maxMagnificationScale
            )
        )
    }

    var body: some View {
        let magnificationGesture = MagnificationGesture()
            .onChanged { value in
                let sensitivity: CGFloat = 0.1 * configuration.zoomSensitivity
                let scaledValue = (value.magnitude - 1) * sensitivity + 1

                let maxScaleValues = viewModel.calculateMagnificationGestureMaxValues()
                viewModel.scale = min(max(scaledValue * viewModel.scale, maxScaleValues.0), maxScaleValues.1)

                let maxOffsetPoint = viewModel.calculateDragGestureMax()
                let newX = min(max(viewModel.lastOffset.width, -maxOffsetPoint.x), maxOffsetPoint.x)
                let newY = min(max(viewModel.lastOffset.height, -maxOffsetPoint.y), maxOffsetPoint.y)
                viewModel.offset = CGSize(width: newX, height: newY)
            }
            .onEnded { _ in
                viewModel.lastScale = viewModel.scale
                viewModel.lastOffset = viewModel.offset
            }

        let dragGesture = DragGesture()
            .onChanged { value in
                let maxOffsetPoint = viewModel.calculateDragGestureMax()
                let newX = min(
                    max(value.translation.width + viewModel.lastOffset.width, -maxOffsetPoint.x),
                    maxOffsetPoint.x
                )
                let newY = min(
                    max(value.translation.height + viewModel.lastOffset.height, -maxOffsetPoint.y),
                    maxOffsetPoint.y
                )
                viewModel.offset = CGSize(width: newX, height: newY)
            }
            .onEnded { _ in
                viewModel.lastOffset = viewModel.offset
            }

        let rotationGesture = RotationGesture()
            .onChanged { value in
                viewModel.angle = value
            }
            .onEnded { _ in
                viewModel.lastAngle = viewModel.angle
            }

        VStack {
            HStack(alignment: .center) {
                Button {
                    dismiss()
                } label: {
                    Image.montage(.close)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .foregroundStyle(Color.alias(.staticWhite))

                Spacer()
                
                Text("이미지 편집")
                    .montage(variant: .headline2, weight: .bold, color: .staticWhite)
                
                Spacer()

                Button {
                    onComplete(cropImage())
                    dismiss()
                } label: {
                    Text("완료")
                        .montage(variant: .headline2, weight: .regular, color: .staticWhite)
                }
                .foregroundStyle(Color.alias(.staticWhite))
            }
            .padding()

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(viewModel.angle)
                    .scaleEffect(viewModel.scale)
                    .offset(viewModel.offset)
                    .opacity(0.5)
                    .overlay(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    viewModel.imageSizeInView = geometry.size
                                }
                        }
                    )

                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(viewModel.angle)
                        .scaleEffect(viewModel.scale)
                        .offset(viewModel.offset)
                        .mask(
                            MaskShapeView(maskShape: maskShape)
                                .frame(
                                    width: viewModel.maskRadius * 2,
                                    height: viewModel.maskRadius * 2
                                )
                        )
                    
                    Rectangle()
                        .stroke(Color.alias(.inverseLabel), lineWidth: 1)
                        .frame(
                            width: viewModel.maskRadius * 2,
                            height: viewModel.maskRadius * 2
                        )
                    
                    DashedCornerRectangle()
                        .stroke(Color.alias(.inverseLabel))
                        .frame(
                            width: viewModel.maskRadius * 2,
                            height: viewModel.maskRadius * 2
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(dragGesture)
            .simultaneousGesture(configuration.rotateImage ? rotationGesture : nil)
        }
        .background(.black)
    }

    private func cropImage() -> UIImage? {
        var editedImage: UIImage = image
        if configuration.rotateImage {
            if let rotatedImage: UIImage = viewModel.rotate(
                editedImage,
                viewModel.lastAngle
            ) {
                editedImage = rotatedImage
            }
        }
        if configuration.cropImageCircular && maskShape == .circle {
            return viewModel.cropToCircle(editedImage)
        } else {
            return viewModel.cropToSquare(editedImage)
        }
    }

    private struct MaskShapeView: View {
        let maskShape: MaskShape

        var body: some View {
            Group {
                switch maskShape {
                case .circle:
                    Circle()

                case .square:
                    Rectangle()
                }
            }
        }
    }
    
    private struct DashedCornerRectangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let dashLength: CGFloat = 20.0
            let lineWidth: CGFloat = 2.0

            // Top left corner
            path.move(to: CGPoint(x: 0, y: dashLength))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: dashLength, y: 0))
            
            // Top right corner
            path.move(to: CGPoint(x: rect.width - dashLength, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: dashLength))
            
            // Bottom right corner
            path.move(to: CGPoint(x: rect.width, y: rect.height - dashLength))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width - dashLength, y: rect.height))
            
            // Bottom left corner
            path.move(to: CGPoint(x: dashLength, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height - dashLength))
            
            return path.strokedPath(StrokeStyle(lineWidth: lineWidth))
        }
    }
}
