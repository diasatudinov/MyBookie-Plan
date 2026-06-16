// MARK: - Bonus Hub

struct BonusHubView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showUsedRewards = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Bonus Hub")
                    .font(.largeTitle.bold())

                HStack(spacing: 0) {
                    SegmentButton(
                        title: "Active Rewards (\(store.activeRewards.count))",
                        isSelected: !showUsedRewards
                    ) {
                        showUsedRewards = false
                    }

                    SegmentButton(
                        title: "Used Rewards (\(store.usedRewards.count))",
                        isSelected: showUsedRewards
                    ) {
                        showUsedRewards = true
                    }
                }
                .padding(4)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if showUsedRewards {
                    ForEach(store.usedRewards) { item in
                        UsedRewardCardView(item: item)
                    }
                } else {
                    if let firstReward = store.activeRewards.first {
                        RewardQRCodeCardView(reward: firstReward)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Active Rewards")
                            .font(.headline)
                            .foregroundColor(.gray)

                        ForEach(store.activeRewards) { reward in
                            RewardSmallCardView(reward: reward)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct RewardQRCodeCardView: View {
    @EnvironmentObject private var store: AppStore

    let reward: Reward

    var body: some View {
        VStack(spacing: 18) {
            QRCodeView(text: reward.qrPayload)
                .frame(width: 220, height: 220)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 8) {
                Text(reward.title)
                    .font(.title3.bold())

                Text(reward.description)
                    .foregroundColor(.gray)

                Label("Expires: \(reward.expiresText)", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("How to use: \(reward.instruction)")
                    .font(.subheadline)
                    .padding()
                    .background(AppTheme.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.useReward(reward)
            } label: {
                Text("Mark Reward as Used")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct RewardSmallCardView: View {
    let reward: Reward

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "gift")
                .foregroundColor(AppTheme.orange)
                .padding()
                .background(AppTheme.orange.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.headline)

                Text(reward.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Expires")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(reward.expiresText)
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct UsedRewardCardView: View {
    let item: UsedReward

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(AppTheme.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.reward.title)
                    .font(.headline)

                Text("Used on \(item.usedAt.shortMonthDay)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QRCodeView: View {
    let text: String

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Image(uiImage: generateQRCode(from: text))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }

        return UIImage(cgImage: cgImage)
    }
}