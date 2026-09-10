/// Export principal du package FileEncryptor Core.
library;

// Entités
export 'src/domain/entities/encrypted_file.dart';
export 'src/domain/entities/encryption_result.dart';
export 'src/domain/entities/history_item.dart';
export 'src/domain/entities/processing_progress.dart';

// Exceptions
export 'src/domain/exceptions/crypto_exceptions.dart';

// Contrats de Repositories
export 'src/domain/repositories/crypto_repository.dart';
export 'src/domain/repositories/file_repository.dart';
export 'src/domain/repositories/history_repository.dart';

// Cas d'utilisation
export 'src/domain/usecases/decrypt_file_usecase.dart';
export 'src/domain/usecases/encrypt_file_usecase.dart';
export 'src/domain/usecases/get_history_usecase.dart';
export 'src/domain/usecases/save_history_usecase.dart';

// Data sources
export 'src/data/datasources/crypto/aes_crypto_engine.dart';
export 'src/data/datasources/io/local_file_service.dart';
export 'src/data/datasources/storage/history_local_datasource.dart';

// Modèles
export 'src/data/models/history_item_model.dart';

// Implémentations concrètes de Repositories
export 'src/data/repositories/crypto_repository_impl.dart';
export 'src/data/repositories/file_repository_impl.dart';
export 'src/data/repositories/history_repository_impl.dart';
