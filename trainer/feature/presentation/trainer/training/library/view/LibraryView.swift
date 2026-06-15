import SwiftUI
import libfitness

struct LibraryView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var workoutSelectionViewModel: WorkoutSelectionViewModel
    @StateObject private var viewModel = LibraryViewModel()

    var body: some View {
        VStack {
            if viewModel.items.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No items found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                List(viewModel.items, id: \.self) { item in
                    Button(action: {
                        handleTap(on: item)
                    }) {
                        HStack {
                            Image(systemName: itemIcon(for: item))
                                .foregroundColor(itemColor(for: item))
                            Text(viewModel.itemDisplayName(item))
                                .foregroundColor(.primary)
                            Spacer()
                            if item.type == AssetProperty.Type_.dir {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("libraryItem_\(viewModel.itemDisplayName(item))")
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(viewModel.isRoot() ? "Library" : (viewModel.pathStack.last ?? "Library"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if viewModel.isRoot() {
                        navigationRouter.navigateBack()
                    } else {
                        viewModel.navigateBack()
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
            }
        }
        .navigationDestination(for: AssetProperty.self) { file in
            LibraryDetailView(file: file, directoryPath: viewModel.currentPath)
                .environmentObject(viewModel)
                .environmentObject(workoutSelectionViewModel)
        }
        .navigationDestination(for: RawMRCViewRoute.self) { route in
            RawMRCView(filePath: route.filePath)
        }
    }

    private func handleTap(on item: AssetProperty) {
        if item.type == AssetProperty.Type_.dir {
            viewModel.navigateTo(directory: viewModel.itemDisplayName(item))
        } else if item.type == AssetProperty.Type_.file {
            navigationRouter.navigate(to: item)
        }
    }

    private func itemIcon(for item: AssetProperty) -> String {
        if item.type == AssetProperty.Type_.dir {
            return "folder.fill"
        } else {
            return "doc.fill"
        }
    }

    private func itemColor(for item: AssetProperty) -> Color {
        if item.type == AssetProperty.Type_.dir {
            return .blue
        } else {
            return .gray
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(BluetoothManager())
        .environmentObject(NavigationRouter())
        .environmentObject(WorkoutSelectionViewModel())
}
