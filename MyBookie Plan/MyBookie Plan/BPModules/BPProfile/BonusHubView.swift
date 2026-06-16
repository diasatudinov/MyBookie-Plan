//
//  BonusHubView.swift
//  MyBookie Plan
//
//

import SwiftUI

// MARK: - Bonus Hub

struct BonusHubView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showUsedRewards = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Bonus Hub")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

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
                            .font(.system(size: 14, weight: .bold))
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
                .frame(width: 295, height: 305)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 8) {
                
                HStack(alignment: .top, spacing: 12) {
                    
                    Image(systemName: "gift")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                        .foregroundColor(AppTheme.orange)
                        .padding()
                        .background(AppTheme.orange.opacity(0.2))
                        .clipShape(Circle())
                        
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reward.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(reward.description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                }
                HStack {
                    Image(systemName: "calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 15)
                        .foregroundColor(AppTheme.orange)
                    VStack(alignment: .leading) {
                        Text("Expires")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.gray)
                        
                        Text("\(reward.expiresText)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.white.opacity(0.10))
                   
                }
                
                Text("How to use: \(reward.instruction)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                .bold()
                .padding()
                .background(AppTheme.orange.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(reward.description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Expires")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Text(reward.expiresText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

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

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 17)
                .background(isSelected ? AppTheme.orange : Color.clear)
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    BonusHubView()
        .environmentObject(AppStore())
}
