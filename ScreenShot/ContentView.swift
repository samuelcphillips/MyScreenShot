import SwiftUI
import Foundation
import CoreMotion

struct ContentView: View {
    @EnvironmentObject var screenshotDetector: ScreenshotDetector
    
    @State private var isUserMessageVisible = false
    @State private var isAlertViewVisible = false
    @State private var rectIsEnlarged = false
    @State private var circleIsEnlarged: [Bool] = [false, false, false, false, false, false, false]
    @State private var backgroundColors: [Color] = [.red, .green, .blue, .orange, .cyan]
    @State private var motionManager = CMMotionManager()
    @State private var xAcceleration: CGFloat = 0.0
    @State private var yAcceleration: CGFloat = 0.0
    
    let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .light)
    let defaults = UserDefaults.standard

    
    var body: some View {
        ZStack {
            //HomeView()
            TransitionView()
            if isUserMessageVisible {
                UserMessageView()
            }
            if isAlertViewVisible {
                AlertView()
            }
            // Add animation and proper overlay settings here
            if screenshotDetector.showView {
                ZStack {
                    RoundedRectangleView(isEnlarged: $rectIsEnlarged)
                        .frame(width: 100, height: 161.8) // RoundedRect dimensions
                        .foregroundColor(.gray)
                        .opacity(0.5)
                        .position(x: UIScreen.main.bounds.size.width - 60, y: 75)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    rectIsEnlarged.toggle()
                                    screenshotDetector.restartTimer()
                                }
                                .onEnded { _ in
                                    rectIsEnlarged.toggle()
                                    screenshotDetector.restartTimer()
                                }
                            )
                    ScrollView {
                        VStack {
                            // Iterate through all user defaults with SS- prefixes, adding a circle view for each item in dictionary
                            let existingPhotoCategories = UserDefaultsController().iterateUserDefaults(withPrefix: "SS-")
                            ForEach(0..<existingPhotoCategories.count, id: \.self) { val in
                                CircleView(isEnlarged: $circleIsEnlarged[val])
                                // Rewrite button actions as function for readability
                                    .foregroundColor(backgroundColors[val])
                                    .onTapGesture {
                                        let savedAlbumName = defaults.object(forKey: "SS-\(val)")
                                        buttonIsTapped(circleNum:val, albumName: savedAlbumName as! String)
                                    }
                            }
                            // Add new category button
                            ZStack {
                                CircleView(isEnlarged:$circleIsEnlarged[6])
                                    .foregroundColor(.blue)
                                    .onTapGesture {
                                        isAlertViewVisible.toggle()
                                        circleIsEnlarged[6].toggle()
                                        delay(seconds: 0.25) {
                                            circleIsEnlarged[6].toggle()
                                        }
                                    }
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 2)
                                    .offset(y: 0)
                                Rectangle()
                                    .foregroundColor(.white)
                                    .frame(width: 2, height: 20)
                                    .offset(x: 0)
                            }
                        }
                    }
                    .frame(width: 110, height: 161.8 / 1.5)
                    .position(x: UIScreen.main.bounds.size.width - 60, y: 75)
                    .background(Color.gray.opacity(0.1))
                }
            }
        }
    }
    
    
    private func delay(seconds: Double, closure: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
        }
    }
    
    private func buttonIsTapped(circleNum: Int, albumName: String) {
        impactFeedbackgenerator.prepare()
        impactFeedbackgenerator.impactOccurred()
        circleIsEnlarged[circleNum].toggle()
        if let mostRecentImage = PhotoHelper().fetchMostRecentImage() {
            PhotoHelper().addImageToAlbum(image: mostRecentImage, albumName: albumName)
        }
        delay(seconds: 0.25) {
            circleIsEnlarged[circleNum].toggle()
            impactFeedbackgenerator.impactOccurred()
        }
        isUserMessageVisible.toggle()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            isUserMessageVisible.toggle()
        }
    }
}

struct CircleView: View {
    @Binding var isEnlarged: Bool
    var body: some View {
        Circle()
            .frame(width: isEnlarged ? 33 : 30, height: isEnlarged ? 33 : 30)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
    }
}

struct RoundedRectangleView: View {
    @Binding var isEnlarged: Bool
    @State private var motionManager = CMMotionManager()
    @State private var xAcceleration: CGFloat = 0.0
    @State private var yAcceleration: CGFloat = 0.0
    
    var body: some View {
        RoundedRectangle(cornerRadius: isEnlarged ? 29.1 : 30)
            .frame(width: isEnlarged ? 100 : 97, height: isEnlarged ? 171.8 : 166.8)
            /*.offset(x: xAcceleration * 10, y: yAcceleration * 10)
            .onAppear {
                startMotionUpdates()
            }
            .onDisappear {
                stopMotionUpdates()
            }*/
    }
    
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 0.1

        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            // Extracting acceleration values
            let gravity = motion.gravity
            xAcceleration = CGFloat(gravity.x)
            yAcceleration = CGFloat(gravity.y)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct AlertView: View {
    @State private var showingAlert = false
    @State private var enteredText = ""
    var body: some View {
        Text("")
            .onAppear {
                showingAlert = true
            }
            .alert("Enter new photo album name", isPresented: $showingAlert) {
                TextField("Enter text", text: $enteredText)
                Button() {
                    if let mostRecentImage = PhotoHelper().fetchMostRecentImage() {
                        PhotoHelper().addAssetToNewAlbum(asset: mostRecentImage, albumName: enteredText, isUserCreated: true)
                        let existingPhotoCategoriesCount = UserDefaultsController().iterateUserDefaults(withPrefix: "SS-").count

                        UserDefaults.standard.set("\(enteredText) (Screenshot)", forKey: "SS-\(existingPhotoCategoriesCount + 1)")
                        UserDefaults.standard.synchronize()
                    }
                    // Need to establish COUNT for user-created albums
                    // Iterate over this count, plus two defaults and user-creation category                    
                    //let defaults = UserDefaults.standard
                    //defaults.set(enteredText + " (Screenshot)", forKey: "SS-0");
                    
                    
                } label: {
                    Text("Submit")
                }
                Button("Cancel", role: .cancel) {
                    // Handle the retry action.
                    print("User cancelled photo album selection.")
                }
            }
    }
}

struct ExampleTextView: View {
    var body: some View {
        Text("EXAMPLE TEXT")
            .transition(.opacity)
    }
}

class UserDefaultsController {
    //    UserDefaultsController().iterateUserDefaults(withPrefix: "SS-")
    public func iterateUserDefaults(withPrefix prefix: String) -> [Dictionary<String, Any>.Keys.Element] {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let filteredKeys = allKeys.filter { $0.hasPrefix(prefix) }

        // Iterate through the filtered keys and retrieve corresponding values
        for key in filteredKeys {
            if let value = UserDefaults.standard.value(forKey: key) {
                print("Key: \(key), Value: \(value)")
                // Do something with the key and value
            }
        }
        print(type(of: filteredKeys))
        return filteredKeys
    }
}

struct UserMessageView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30.0)
                .frame(width: 225, height: 75)
                .position(x: UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 5) * 4)
                .foregroundColor(.gray)
                .opacity(0.5)
                .cornerRadius(10)
            Text("Added image to album")
                .foregroundColor(.white)
                .font(.body)
                .position(x: UIScreen.main.bounds.size.width / 2, y: (UIScreen.main.bounds.size.height / 5) * 4)
                .multilineTextAlignment(.center)
        }
    }
}

struct TransitionView: View {
    @State private var backgroundColors: [Color] = [.red, .green, .blue, .orange, .cyan]
    @State private var currentIndex = 0
    
    @State var motionManager = CMMotionManager()
    @State var xAcceleration: CGFloat = 0.0
    @State var yAcceleration: CGFloat = 0.0

    var body: some View {
        ZStack {
            backgroundColors[currentIndex]
                .edgesIgnoringSafeArea(.all)
            VStack {
                LottieView(animationName: "AllAnimals", loopMode: .loop)
                    .frame(width: 400, height: 400) // temporary fix: forces bottom text up and may only work on iPhone 11
                    .offset(x: xAcceleration * 10, y: yAcceleration * 10)
                    .onAppear {
                        startMotionUpdates()
                    }
                    .onDisappear {
                        stopMotionUpdates()
                    }
                Text("Take a screenshot! \n Animation credit: @tomfabre")
                    .multilineTextAlignment(.center)
                    .offset(x: xAcceleration * 10, y: yAcceleration * 10)
                    .onAppear {
                        startMotionUpdates()
                    }
                    .onDisappear {
                        stopMotionUpdates()
                    }
                    
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                withAnimation {
                    currentIndex = (currentIndex + 1) % backgroundColors.count
                }
            }
        }
    }
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 0.1

        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            // Extracting acceleration values
            let gravity = motion.gravity
            xAcceleration = CGFloat(gravity.x)
            yAcceleration = CGFloat(gravity.y)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct ParallaxRectangle: View {
    @State private var motionManager = CMMotionManager()
    @State private var xAcceleration: CGFloat = 0.0
    @State private var yAcceleration: CGFloat = 0.0

    var body: some View {
        Rectangle()
            .frame(width: 200, height: 100)
            .foregroundColor(.blue)
            .offset(x: xAcceleration * 20, y: yAcceleration * 20)
            .onAppear {
                startMotionUpdates()
            }
            .onDisappear {
                stopMotionUpdates()
            }
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 0.1

        motionManager.startDeviceMotionUpdates(to: .main) { motion, error in
            guard let motion = motion else { return }

            // Extracting acceleration values
            let gravity = motion.gravity
            xAcceleration = CGFloat(gravity.x)
            yAcceleration = CGFloat(gravity.y)
        }
    }

    private func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}
