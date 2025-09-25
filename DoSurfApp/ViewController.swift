import UIKit
import FirebaseCore
import FirebaseFirestore

class ViewController: UIViewController {

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1) 특정 문서 읽기: /regions/강릉/beaches/jeongdongjin/forecasts/202509242300
        readDocument(path: ["regions", "강릉",
                            "beaches", "jeongdongjin",
                            "forecasts", "202509242300"])

        // 2) 특정 컬렉션의 모든 문서 읽기: /regions/강릉/beaches/jeongdongjin/forecasts
        readCollection(path: ["regions", "강릉",
                              "beaches", "jeongdongjin",
                              "forecasts"])

        // 3) 전체 프로젝트에서 이름이 "forecasts"인 모든 하위컬렉션 문서 모으기
        // readAllForecastsByCollectionGroup()
    }

    // MARK: - Helpers

    /// 문서 경로(컬렉션/문서/.../컬렉션/문서) 하나 읽기
    private func readDocument(path: [String]) {
        guard path.count % 2 == 0 else {
            print("❌ 문서 경로는 [컬렉션,문서,컬렉션,문서,...] 짝수 길이여야 합니다.")
            return
        }
        var ref: DocumentReference = db.collection(path[0]).document(path[1])
        var i = 2
        while i < path.count {
            let col = path[i]
            let doc = path[i+1]
            ref = ref.collection(col).document(doc)
            i += 2
        }

        ref.getDocument { snap, err in
            if let err = err {
                print("❌ getDocument 에러:", err)
                return
            }
            guard let snap = snap, snap.exists else {
                print("⚠️ 문서가 없음:", ref.path)
                return
            }
            print("✅ 문서 읽음:", snap.reference.path)
            print("📦 데이터:", snap.data() ?? [:])
        }
    }

    /// 컬렉션 경로(컬렉션/문서/.../컬렉션) 모든 문서 읽기
    private func readCollection(path: [String]) {
        guard path.count % 2 == 1 else {
            print("❌ 컬렉션 경로는 [컬렉션,문서, ... ,컬렉션] 홀수 길이여야 합니다.")
            return
        }
        var collRef: CollectionReference = db.collection(path[0])
        var i = 1
        while i < path.count {
            let doc = path[i]
            if i + 1 < path.count {
                let nextCol = path[i+1]
                collRef = collRef.document(doc).collection(nextCol)
                i += 2
            } else {
                // 마지막은 컬렉션이어야 함
                break
            }
        }

        collRef.getDocuments { snap, err in
            if let err = err {
                print("❌ getDocuments 에러:", err)
                return
            }
            let docs = snap?.documents ?? []
            print("✅ \(collRef.path) 총 \(docs.count)개 문서")
            for d in docs {
                print("— ID:", d.documentID, " data:", d.data())
            }
        }
    }

    /// 모든 위치의 하위컬렉션 "forecasts" 문서 전부 가져오기 (collectionGroup)
    private func readAllForecastsByCollectionGroup() {
        db.collectionGroup("forecasts").getDocuments { snap, err in
            if let err = err {
                print("❌ collectionGroup 에러:", err)
                return
            }
            let docs = snap?.documents ?? []
            print("🌐 forecasts 전체 수:", docs.count)
            for d in docs.prefix(20) { // 너무 많을 수 있으니 일부만 프린트
                print("—", d.reference.path, d.data())
            }
        }
    }
}
