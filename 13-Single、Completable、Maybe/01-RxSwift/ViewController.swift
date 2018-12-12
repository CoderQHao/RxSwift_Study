//
//  ViewController.swift
//  01-RxSwift
//
//  Created by Qing ’s on 2018/11/28.
//  Copyright © 2018 Qing ’s. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!
    
    //负责对象销毁
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*---------------------------------------Single---------------------------------------*/
        // 获取第0个频道的歌曲信息
        getPlaylist("0").subscribe { (event) in
            switch event {
            case .success(let json):
                print("JSON结果：",json)
            case .error(let error):
                print("发生错误：",error)
            }
        }.disposed(by: disposeBag)
        
        // 获取第1个频道的歌曲信息
        getPlaylist("1").subscribe(onSuccess: { (json) in
            print("JSON结果：",json)
        }) { (error) in
            print("发生错误：",error)
        }.disposed(by: disposeBag)
        
        
        asSingle()
        
        /*---------------------------------------Completable---------------------------------------*/
        cacheLocally()
            .subscribe { completable in
                switch completable {
                case .completed:
                    print("保存成功!")
                case .error(let error):
                    print("保存失败: \(error.localizedDescription)")
                }
            }
            .disposed(by: disposeBag)

        cacheLocally()
            .subscribe(onCompleted: {
                print("保存成功!")
            }, onError: { error in
                print("保存失败: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)

        /*---------------------------------------Maybe---------------------------------------*/
        generateString()
            .subscribe { maybe in
                switch maybe {
                case .success(let element):
                    print("执行完毕，并获得元素：\(element)")
                case .completed:
                    print("执行完毕，且没有任何元素。")
                case .error(let error):
                    print("执行失败: \(error.localizedDescription)")
                    
                }
            }
            .disposed(by: disposeBag)
        
        generateString()
            .subscribe(onSuccess: { element in
                print("执行完毕，并获得元素：\(element)")
            },
                       onError: { error in
                        print("执行失败: \(error.localizedDescription)")
            },
                       onCompleted: {
                        print("执行完毕，且没有任何元素。")
            })
            .disposed(by: disposeBag)
        
        asMaybe()
    }
    
    /*
     Single 是 Observable 的另外一个版本。但它不像 Observable 可以发出多个元素，它要么只能发出一个元素，要么产生一个 error 事件。
     发出一个元素，或一个 error 事件
     不会共享状态变化
     Single 比较常见的例子就是执行 HTTP 请求，然后返回一个应答或错误。不过我们也可以用 Single 来描述任何只有一个元素的序列。
     为方便使用，RxSwift 还为 Single 订阅提供了一个枚举（SingleEvent）：
     .success：里面包含该 Single 的一个元素值
     .error：用于包含错误
     public enum SingleEvent<Element> {
        case success(Element)
        case error(Swift.Error)
     }
     */
    func getPlaylist(_ channel: String) -> Single<[String: Any]> {
        return Single<[String: Any]>.create(subscribe: { (single) -> Disposable in
            let url = "https://douban.fm/j/mine/playlist?" + "type=n&channel=\(channel)&from=mainsite"
            let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, _, error) in
                if let error = error {
                    single(.error(error))
                    return
                }
                guard let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: .mutableLeaves),
                    let result = json as? [String: Any] else {
                        single(.error(DataError.cantParseJSON))
                        return
                }
                single(.success(result))
            })
            
            task.resume()
            return Disposables.create {
                task.cancel()
            }
        })
    }
    
    func asSingle() {
        let disposeBag = DisposeBag()
        
        Observable.of("1")
            .asSingle()
            .subscribe({ print($0) })
            .disposed(by: disposeBag)
    }
    
    /*
     Completable 是 Observable 的另外一个版本。不像 Observable 可以发出多个元素，它要么只能产生一个 completed 事件，要么产生一个 error 事件。
     不会发出任何元素
     只会发出一个 completed 事件或者一个 error 事件
     不会共享状态变化
     Completable 和 Observable<Void> 有点类似。适用于那些只关心任务是否完成，而不需要在意任务返回值的情况。比如：在程序退出时将一些数据缓存到本地文件，供下次启动时加载。像这种情况我们只关心缓存是否成功。
     
     为方便使用，RxSwift 为 Completable 订阅提供了一个枚举（CompletableEvent）：
     .completed：用于产生完成事件
     .error：用于产生一个错误
     public enum CompletableEvent {
        case error(Swift.Error)
        case completed
     }
     */
    
    //将数据缓存到本地
    func cacheLocally() -> Completable {
        return Completable.create { completable in
            //将数据缓存到本地（这里掠过具体的业务代码，随机成功或失败）
            let success = (arc4random() % 2 == 0)
            
            guard success else {
                completable(.error(CacheError.failedCaching))
                return Disposables.create {}
            }
            
            completable(.completed)
            return Disposables.create {}
        }
    }
    
    /*
     Maybe 同样是 Observable 的另外一个版本。它介于 Single 和 Completable 之间，它要么只能发出一个元素，要么产生一个 completed 事件，要么产生一个 error 事件。
     发出一个元素、或者一个 completed 事件、或者一个 error 事件
     不会共享状态变化
     
     Maybe 适合那种可能需要发出一个元素，又可能不需要发出的情况。
     
     为方便使用，RxSwift 为 Maybe 订阅提供了一个枚举（MaybeEvent）：
     .success：里包含该 Maybe 的一个元素值
     .completed：用于产生完成事件
     .error：用于产生一个错误
     public enum MaybeEvent<Element> {
         case success(Element)
         case error(Swift.Error)
         case completed
     }
     */
    func generateString() -> Maybe<String> {
        return Maybe<String>.create { maybe in
            
            //成功并发出一个元素
            maybe(.success("hangge.com"))
            
            //成功但不发出任何元素
            maybe(.completed)
            
            //失败
            //maybe(.error(StringError.failedGenerate))
            
            return Disposables.create {}
        }
    }
        
        func asMaybe() {
            Observable.of("1")
                .asMaybe()
                .subscribe({ print($0) })
                .disposed(by: disposeBag)
        }
}

//与数据相关的错误类型
enum DataError: Error {
    case cantParseJSON
}

//与缓存相关的错误类型
enum CacheError: Error {
    case failedCaching
}

//与缓存相关的错误类型
enum StringError: Error {
    case failedGenerate
}




