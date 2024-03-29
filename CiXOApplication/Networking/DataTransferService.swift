//
//  DataTransferService.swift
//  CiXOApplication
//
//  Created by Nguyen Thien on 24/02/2024.
//

import Foundation

protocol DataTransferQueue {
    func asyncExecute(_ block: @escaping () -> Void)
}

extension DispatchQueue: DataTransferQueue {
    func asyncExecute(_ block: @escaping () -> Void) {
        async(execute: block)
    }
}

enum DataTransferError: Error {
    case noResponse
    case parsing(Error)
    case general(Error)
}

protocol DataTransferService {
    typealias CompletionHandler<T> = (Result<T, DataTransferError>) -> Void
    
    func request<T: Decodable, R: ReponsableRequestable>(endpoint: R,
                                                         on queue: DataTransferQueue,
                                                         completion: @escaping CompletionHandler<T>) -> Cancellable? where R.Response == T
    
    func request<R: ReponsableRequestable>(endpoint: R,
                                           on queue: DataTransferQueue,
                                           completion: @escaping CompletionHandler<Void>) -> Cancellable? where R.Response == Void
}

final class DefaultDataTransferService: DataTransferService {
    
    private let service: NetworkService
    
    init(service: NetworkService) {
        self.service = service
    }
    
    func request<T, R>(endpoint: R, on queue: DataTransferQueue, completion: @escaping CompletionHandler<T>) -> Cancellable? where T : Decodable, T == R.Response, R : ReponsableRequestable {
        service.request(endpoint: endpoint) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(data):
                let result: Result<T, DataTransferError> = self.decode(from: data, decoder: endpoint.responseDecoder)
                queue.asyncExecute {
                    completion(result)
                }
            case let .failure(error):
                queue.asyncExecute {
                    completion(.failure(.general(error)))
                }
            }
        }
    }
    
    func request<R>(endpoint: R, on queue: DataTransferQueue, completion: @escaping CompletionHandler<Void>) -> Cancellable? where R : ReponsableRequestable, R.Response == () {
        service.request(endpoint: endpoint) { result in
            switch result {
            case .success:
                queue.asyncExecute { completion(.success(())) }
            case let .failure(error):
                queue.asyncExecute { completion(.failure(.general(error))) }
            }
        }
    }
}

private extension DefaultDataTransferService {
    func decode<T: Decodable>(from data: Data?, decoder: ResponseDecoder) -> Result<T, DataTransferError> {
        guard let data else { return .failure(.noResponse) }
        do {
            let result: T = try decoder.decode(data)
            return .success(result)
        } catch {
            return .failure(.parsing(error))
        }
    }
}
