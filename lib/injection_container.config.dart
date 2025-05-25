// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import 'core/config/app_config.dart' as _i828;
import 'core/config/settings_service.dart' as _i12;
import 'core/providers/locale_provider.dart' as _i766;
import 'core/providers/theme_provider.dart' as _i622;
import 'features/auth/data/datasources/auth_remote_data_source.dart' as _i767;
import 'features/auth/data/repositories/auth_repository_impl.dart' as _i111;
import 'features/auth/domain/repositories/auth_repository.dart' as _i1015;
import 'features/auth/presentation/bloc/auth_bloc.dart' as _i363;
import 'features/bill_history/data/datasources/bill_history_remote_data_source.dart'
    as _i773;
import 'features/bill_history/data/datasources/bill_history_remote_data_source_impl.dart'
    as _i904;
import 'features/bill_history/data/repositories/bill_history_repository_impl.dart'
    as _i562;
import 'features/bill_history/domain/repositories/bill_history_repository.dart'
    as _i590;
import 'features/bill_history/domain/usecases/delete_bill_from_history_usecase.dart'
    as _i32;
import 'features/bill_history/domain/usecases/get_bill_details_from_history_usecase.dart'
    as _i171;
import 'features/bill_history/domain/usecases/get_bill_history_usecase.dart'
    as _i161;
import 'features/bill_history/domain/usecases/save_bill_to_history_usecase.dart'
    as _i661;
import 'features/bill_history/domain/usecases/update_bill_in_history_usecase.dart'
    as _i643;
import 'features/bill_history/presentation/bloc/bill_history_bloc.dart'
    as _i509;
import 'features/bill_splitting/data/datasources/bill_remote_data_source.dart'
    as _i747;
import 'features/bill_splitting/data/datasources/bill_remote_data_source_impl.dart'
    as _i1073;
import 'features/bill_splitting/data/datasources/chat_data_source.dart'
    as _i232;
import 'features/bill_splitting/data/datasources/chat_data_source_impl.dart'
    as _i103;
import 'features/bill_splitting/data/datasources/ocr_data_source.dart' as _i868;
import 'features/bill_splitting/data/datasources/ocr_data_source_impl.dart'
    as _i729;
import 'features/bill_splitting/data/repositories/bill_repository_impl.dart'
    as _i29;
import 'features/bill_splitting/domain/repositories/bill_repository.dart'
    as _i765;
import 'features/bill_splitting/domain/usecases/create_bill_usecase.dart'
    as _i1034;
import 'features/bill_splitting/domain/usecases/delete_bill_usecase.dart'
    as _i770;
import 'features/bill_splitting/domain/usecases/get_bills_usecase.dart'
    as _i950;
import 'features/bill_splitting/domain/usecases/process_bill_ocr_usecase.dart'
    as _i10;
import 'features/bill_splitting/domain/usecases/send_chat_message_usecase.dart'
    as _i646;
import 'features/bill_splitting/domain/usecases/update_bill_usecase.dart'
    as _i676;
import 'features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'
    as _i802;
import 'injection_module.dart' as _i212;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i828.AppConfig>(() => _i828.AppConfig.fromEnv());
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i773.BillHistoryRemoteDataSource>(() =>
        _i904.BillHistoryRemoteDataSourceImpl(
            supabase: gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i766.LocaleProvider>(
        () => registerModule.localeProvider(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i622.ThemeProvider>(
        () => registerModule.themeProvider(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i12.SettingsService>(
        () => registerModule.settingsService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i232.ChatDataSource>(() => _i103.ChatDataSourceImpl(
          httpClient: gh<_i519.Client>(),
          appConfig: gh<_i828.AppConfig>(),
          settingsService: gh<_i12.SettingsService>(),
        ));
    gh.lazySingleton<_i590.BillHistoryRepository>(() =>
        _i562.BillHistoryRepositoryImpl(
            remoteDataSource: gh<_i773.BillHistoryRemoteDataSource>()));
    gh.lazySingleton<_i767.AuthRemoteDataSource>(
        () => _i767.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i747.BillRemoteDataSource>(
        () => _i1073.BillRemoteDataSourceImpl(gh<_i454.SupabaseClient>()));
    gh.lazySingleton<_i32.DeleteBillFromHistoryUseCase>(() =>
        _i32.DeleteBillFromHistoryUseCase(gh<_i590.BillHistoryRepository>()));
    gh.lazySingleton<_i171.GetBillDetailsFromHistoryUseCase>(() =>
        _i171.GetBillDetailsFromHistoryUseCase(
            gh<_i590.BillHistoryRepository>()));
    gh.lazySingleton<_i161.GetBillHistoryUseCase>(
        () => _i161.GetBillHistoryUseCase(gh<_i590.BillHistoryRepository>()));
    gh.lazySingleton<_i661.SaveBillToHistoryUseCase>(() =>
        _i661.SaveBillToHistoryUseCase(gh<_i590.BillHistoryRepository>()));
    gh.lazySingleton<_i643.UpdateBillInHistoryUseCase>(() =>
        _i643.UpdateBillInHistoryUseCase(gh<_i590.BillHistoryRepository>()));
    gh.lazySingleton<_i646.SendChatMessageUseCase>(
        () => _i646.SendChatMessageUseCase(
              gh<_i232.ChatDataSource>(),
              gh<_i766.LocaleProvider>(),
            ));
    gh.lazySingleton<_i765.BillRepository>(() => _i29.BillRepositoryImpl(
        remoteDataSource: gh<_i747.BillRemoteDataSource>()));
    gh.lazySingleton<_i1015.AuthRepository>(() => _i111.AuthRepositoryImpl(
        remoteDataSource: gh<_i767.AuthRemoteDataSource>()));
    gh.lazySingleton<_i868.OcrDataSource>(() => _i729.OcrDataSourceImpl(
          httpClient: gh<_i519.Client>(),
          appConfig: gh<_i828.AppConfig>(),
          settingsService: gh<_i12.SettingsService>(),
        ));
    gh.lazySingleton<_i1034.CreateBillUseCase>(
        () => _i1034.CreateBillUseCase(gh<_i765.BillRepository>()));
    gh.lazySingleton<_i770.DeleteBillUseCase>(
        () => _i770.DeleteBillUseCase(gh<_i765.BillRepository>()));
    gh.lazySingleton<_i950.GetBillsUseCase>(
        () => _i950.GetBillsUseCase(gh<_i765.BillRepository>()));
    gh.lazySingleton<_i676.UpdateBillUseCase>(
        () => _i676.UpdateBillUseCase(gh<_i765.BillRepository>()));
    gh.factory<_i509.BillHistoryBloc>(() => _i509.BillHistoryBloc(
          getBillHistoryUseCase: gh<_i161.GetBillHistoryUseCase>(),
          getBillDetailsFromHistoryUseCase:
              gh<_i171.GetBillDetailsFromHistoryUseCase>(),
          saveBillToHistoryUseCase: gh<_i661.SaveBillToHistoryUseCase>(),
          updateBillInHistoryUseCase: gh<_i643.UpdateBillInHistoryUseCase>(),
          deleteBillFromHistoryUseCase: gh<_i32.DeleteBillFromHistoryUseCase>(),
        ));
    gh.lazySingleton<_i10.ProcessBillOcrUseCase>(
        () => _i10.ProcessBillOcrUseCase(gh<_i868.OcrDataSource>()));
    gh.factory<_i363.AuthBloc>(
        () => _i363.AuthBloc(gh<_i1015.AuthRepository>()));
    gh.lazySingleton<_i802.BillSplittingBloc>(() => _i802.BillSplittingBloc(
          gh<_i950.GetBillsUseCase>(),
          gh<_i10.ProcessBillOcrUseCase>(),
          gh<_i1034.CreateBillUseCase>(),
          gh<_i676.UpdateBillUseCase>(),
          gh<_i770.DeleteBillUseCase>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i212.RegisterModule {}
