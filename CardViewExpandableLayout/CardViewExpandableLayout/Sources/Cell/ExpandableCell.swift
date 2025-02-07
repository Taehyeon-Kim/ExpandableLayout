//
//  ExpandableCell.swift
//  CardViewExpandableLayout
//
//  Created by taekki on 2023/01/01.
//

import UIKit

import RxCocoa
import RxDataSources
import RxSwift
import SnapKit

final class ExpandableCell: BaseCollectionViewCell {

  // Properties
  var item: ExpandableViewSection? { didSet { updateContent() } }
  override var isSelected: Bool { didSet { updateAppearance() } }

  private let dataSource: RxCollectionViewSectionedReloadDataSource<ExpandableViewSection>!
  private var sections = BehaviorRelay<[ExpandableViewSection]>(value: [])
  
  // Identifier
  static let identifier = NSStringFromClass(ExpandableCell.self)

  // UI
  private let nameLabel: UILabel = {
    let nameLabel = UILabel()
    nameLabel.font = .preferredFont(forTextStyle: .headline)
    return nameLabel
  }()

  private let collectionView: UICollectionView = {
    lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
    return collectionView
  }()
  
  private let disclosureIndicator: UIImageView = {
    let disclosureIndicator = UIImageView()
    disclosureIndicator.image = UIImage(systemName: "chevron.down")
    disclosureIndicator.contentMode = .scaleAspectFit
    disclosureIndicator.preferredSymbolConfiguration = .init(textStyle: .body, scale: .small)
    return disclosureIndicator
  }()
  
  // Stack
  private lazy var rootStack: UIStackView = {
    let rootStack = UIStackView(arrangedSubviews: [
      nameLabel,
      collectionView
    ])
    rootStack.axis = .vertical
    rootStack.spacing = padding
    return rootStack
  }()
  
  // Constraints
  private var closedConstraint: Constraint?
  private var openConstraint: Constraint?
  
  // Layout
  private let padding: CGFloat = 8
  private let cornerRadius: CGFloat = 8
  private var collectionViewHeight: CGFloat = 1
  
  override init(frame: CGRect) {
    dataSource = Self.dataSourceFactory()
    super.init(frame: frame)
    setUp()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    let newHeight = collectionView.contentSize.height
    
    if collectionView.contentSize.height != 0 {
      collectionViewHeight = newHeight
      collectionView.snp.updateConstraints {
        $0.height.equalTo(collectionViewHeight)
      }
    }
  }
  
  private func setUp() {
    backgroundColor = .systemGray6
    clipsToBounds = true
    layer.cornerRadius = cornerRadius

    setConstraints()
    updateAppearance()
    setCollectionView()
    setBinding()
  }
 
  private func setConstraints() {
    contentView.addSubview(rootStack)
    contentView.addSubview(disclosureIndicator)
    
    contentView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
    
    rootStack.snp.makeConstraints {
      $0.top.directionalHorizontalEdges.equalToSuperview().inset(padding)
    }
    
    disclosureIndicator.snp.makeConstraints {
      $0.top.trailing.equalToSuperview().inset(padding)
    }
    
    // ContentSize가 잡히도록 최초에 최소 영역 설정
    collectionView.snp.makeConstraints {
      $0.height.equalTo(collectionViewHeight)
    }
    
    nameLabel.snp.makeConstraints {
      closedConstraint = $0.bottom.equalTo(contentView.snp.bottom).inset(padding).priority(.low).constraint
    }
    
    collectionView.snp.makeConstraints {
      openConstraint = $0.bottom.equalTo(contentView.snp.bottom).inset(padding).priority(.low).constraint
    }
  }
  
  private func updateContent() {
    guard let _ = item else { return }
    nameLabel.text = "OUTER TITLE"
  }

  private func updateAppearance() {
    closedConstraint?.isActive = !isSelected
    openConstraint?.isActive = isSelected
    
    UIView.animate(withDuration: 0.3) {
      let upsideDown = CGAffineTransform(rotationAngle: .pi * 0.999 )
      self.disclosureIndicator.transform = self.isSelected ? upsideDown :.identity
    }
  }
  
  private func setCollectionView() {
    collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
    collectionView.register(ReputationCollectionViewCell.self, forCellWithReuseIdentifier: ReputationCollectionViewCell.identifier)
    collectionView.register(StudyCollectionViewCell.self, forCellWithReuseIdentifier: StudyCollectionViewCell.identifier)
    collectionView.register(ReviewCollectionViewCell.self, forCellWithReuseIdentifier: ReviewCollectionViewCell.identifier)
  }
  
  private static func dataSourceFactory() -> RxCollectionViewSectionedReloadDataSource<ExpandableViewSection> {
    return .init { dataSource, collectionView, indexPath, item in
      switch dataSource[indexPath.section] {
      case .reputation(let item):
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReputationCollectionViewCell.identifier, for: indexPath) as! ReputationCollectionViewCell
        cell.configure(item[indexPath.row])
        return cell
        
      case .study(let item):
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StudyCollectionViewCell.identifier, for: indexPath) as! StudyCollectionViewCell
        cell.configure(item[indexPath.row])
        return cell
        
      case .review(let item):
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReviewCollectionViewCell.identifier, for: indexPath) as! ReviewCollectionViewCell
        cell.configure(item[indexPath.row])
        return cell
      }
    } configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
      let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
      return header
    }
  }

  private func setBinding() {
    sections.accept(CardElement.dummy)
    sections
      .bind(to: collectionView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
  }
}

// MARK: CollectionView Layout

extension ExpandableCell {
  
  private static func createLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/2), heightDimension: .estimated(37))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(37))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
    group.interItemSpacing = .fixed(5)
    
    let section = NSCollectionLayoutSection(group: group)
    section.interGroupSpacing = 5
    section.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
    section.boundarySupplementaryItems = [Self.createHeaderLayout()]
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  private static func createHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(40))
    return NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
  }
}
