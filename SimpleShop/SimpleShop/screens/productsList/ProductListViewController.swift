//
//  ProductListViewController.swift
//  SimpleShop
//
//  Created by Anton Ihnatovich on 1/16/19.
//  Copyright © 2019 Ihnatovich. All rights reserved.
//

import Foundation
import UIKit

class ProductListViewController: UIViewController {
    
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var progressView: ProgressView!
    private(set) var viewModel: ProductsListViewModel?
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = ProductsListViewModel()
        bindViewModel()
        collectionView.register(UINib(nibName: "ProductCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: Cell.productCell.rawValue)
        setupCollectionViewRefreshControl()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    deinit {
        Swift.print("[ProductListViewController] deinit")
    }
    
    private func bindViewModel() {
        
        guard let viewModel = viewModel else { return }
        
        viewModel.updateUI = { [weak self] in
            self?.retryButton.isHidden = true
            self?.refreshControl.endRefreshing()
            self?.collectionView.reloadData()
        }
        
        viewModel.showError = { [weak self] error in
            if let err = error as? NetworkError, err == .noInternet {
                self?.retryButton.isHidden = false
            }
            self?.showError(title: NSLocalizedString("alert.error.title", comment: ""), message: (error as? NetworkError)?.localizedDescription ?? NSLocalizedString("error.unrecognizedError", comment: ""))
        }
        
        viewModel.presentProgress = { [weak self] state in
            UIApplication.shared.isNetworkActivityIndicatorVisible = state
            if state {
                self?.progressView.present(with: Progress.updating.rawValue, animated: true)
            } else {
                self?.progressView.hide(animated: true)
            }
        }
        
        viewModel.presentDetail = { [weak self] id in
            let storyboard = UIStoryboard.init(name: "ProductDetailed", bundle: .main)
            guard let controller = storyboard.instantiateInitialViewController() as? ProductDetailedViewController else { return }
            controller.productId = id
            self?.navigationController?.pushViewController(controller, animated: true)
        }
        
        viewModel.loadItems()
    }
    
    private func setupCollectionViewRefreshControl() {
        collectionView.refreshControl = refreshControl
        collectionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(ProductListViewController.refreshInitiated(_:)), for: .valueChanged)
    }
    
    @objc private func refreshInitiated(_ sender: UIRefreshControl) {
        viewModel?.loadItems()
    }
    
    // MARK: IBActions
    @IBAction func reloadButtonDidPress(_ sender: UIButton) {
        viewModel?.loadItems()
    }
    
    private class Constants {
        static let cellPadding: CGFloat = 20
        private static let visibleCellColumnsVertical: CGFloat = 2
        private static let visibleCellRowsVertical: CGFloat = 2.5
        private static let visibleCellColumsHorizontal: CGFloat = 2
        private static let visibleCellRowsHorizontal: CGFloat = 1.5
        
        static var cellCountPerColumn: CGFloat {
            let isInVerticalOrientation = UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
            return isInVerticalOrientation ? Constants.visibleCellColumnsVertical : Constants.visibleCellColumsHorizontal
        }
        
        static var cellCountPerRow: CGFloat {
            let isInVerticalOrientation = UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown
            return isInVerticalOrientation ? Constants.visibleCellRowsVertical : Constants.visibleCellRowsHorizontal
        }
    }
}

// MARK: UICollectionViewDataSource
extension ProductListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.productCell.rawValue, for: indexPath) as? ProductCollectionViewCell else { return UICollectionViewCell() }
        if let item = viewModel?.item(at: indexPath.row) {
            cell.update(with: item)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.itemsCount() ?? 0
    }
}

// MARK: UICollectionViewDelegate
extension ProductListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel?.didSelectItem(at: indexPath.row)
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension ProductListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let calculatedWidth = (collectionView.frame.size.width - Constants.cellPadding) / Constants.cellCountPerColumn
        let calculatedHeight = (collectionView.frame.size.height - Constants.cellPadding) / Constants.cellCountPerRow
        return CGSize(width: calculatedWidth, height: calculatedHeight)
    }
}
