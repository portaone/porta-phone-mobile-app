// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get account_selfCarePasswordExpired_message =>
      'Sua senha do autoatendimento expirou. Atualize-a pelo autoatendimento.\nAté que a senha seja alterada, o acesso ao serviço ficará limitado.';

  @override
  String get actionpad_SemanticsLabel_backspace => 'Apagar';

  @override
  String agoTicker_daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'há $days dias',
      one: 'há $days dia',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String agoTicker_hoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'há $hours horas',
      one: 'há $hours hora',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String agoTicker_minutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'há $minutes minutos',
      one: 'há $minutes minuto',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String agoTicker_secondsAgo(num seconds) {
    final intl.NumberFormat secondsNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'há $secondsString segundos',
      one: 'há $secondsString segundo',
      zero: 'Agora mesmo',
    );
    return '$_temp0';
  }

  @override
  String get alertDialogActions_no => 'Não';

  @override
  String get alertDialogActions_ok => 'Ok';

  @override
  String get alertDialogActions_yes => 'Sim';

  @override
  String get autoprovision_errorSnackBar_invalidToken =>
      'As credenciais de configuração automática foram rejeitadas pelo servidor. Solicite um novo link de configuração';

  @override
  String get autoprovision_ReloginDialog_confirm => 'Confirmar';

  @override
  String get autoprovision_ReloginDialog_decline => 'Recusar';

  @override
  String get autoprovision_ReloginDialog_text =>
      'Deseja usar as novas credenciais de autenticação fornecidas no link? Você será desconectado da sessão atual.';

  @override
  String get autoprovision_ReloginDialog_title => 'Confirmação de novo login';

  @override
  String get autoprovision_successSnackBar_used =>
      'Suas configurações foram obtidas com sucesso, o app está pronto para uso';

  @override
  String get callCenter_AppBarTitle => 'Minhas filas';

  @override
  String get callCenter_Button_retry => 'Tentar novamente';

  @override
  String get callCenter_Snackbar_changeFailed => 'Não foi possível alterar seu status na fila. Tente novamente.';

  @override
  String get callCenter_Snackbar_queueGone => 'Essa fila não é mais sua. A lista foi atualizada.';

  @override
  String get callCenter_Snackbar_readOnly =>
      'O servidor está em modo somente leitura no momento, por isso o status na fila não pode ser alterado.';

  @override
  String get callCenter_Switch_allQueues => 'Todas as filas';

  @override
  String callCenter_Text_agentsOfTotal(int loggedIn, int total) {
    return '$loggedIn de $total agentes';
  }

  @override
  String get callCenter_Text_loadFailed => 'Não foi possível carregar suas filas.';

  @override
  String callCenter_Text_callersWaiting(int count) {
    return '$count em espera';
  }

  @override
  String get callCenter_Text_callersWaitingUnknown => '— em espera';

  @override
  String callCenter_Text_loggedInOfTotal(int loggedIn, int total) {
    return 'Atendendo chamadas de $loggedIn de $total filas';
  }

  @override
  String get callCenter_Text_noQueues => 'Você não é agente de nenhuma fila de chamadas.';

  @override
  String get callCenter_Text_offline => 'Offline';

  @override
  String get callCenter_Text_online => 'Online';

  @override
  String get callTileActions_contact => 'Contato';

  @override
  String get callTileActions_history => 'Histórico';

  @override
  String get callTileActions_message => 'Mensagem';

  @override
  String cacheManagement_Watch_clearQuestion(String name) {
    return 'Limpar $name?';
  }

  @override
  String get cacheManagement_Button_clear => 'Limpar';

  @override
  String get cacheManagement_Label_empty => 'Não há nada em cache neste dispositivo';

  @override
  String cacheManagement_Label_itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count registros', one: '$count registro');
    return '$_temp0';
  }

  @override
  String cacheManagement_Label_sizeBytes(String size) {
    return '$size B';
  }

  @override
  String cacheManagement_Label_sizeGigabytes(String size) {
    return '$size GB';
  }

  @override
  String cacheManagement_Label_sizeKilobytes(String size) {
    return '$size KB';
  }

  @override
  String cacheManagement_Label_sizeMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get cacheManagement_Label_unknown => 'Desconhecido';

  @override
  String get cacheManagement_Widget_screenTitle => 'Armazenamento e cache';

  @override
  String get callTileActions_more => 'Mais';

  @override
  String get call_SemanticsLabel_hideControls => 'Ocultar controles da chamada';

  @override
  String get call_SemanticsLabel_showControls => 'Mostrar controles da chamada';

  @override
  String get keypad_SemanticsLabel_number => 'Número de telefone';

  @override
  String get keypad_SemanticsAction_paste => 'Colar um número';

  @override
  String get callCameraPreview_SemanticsLabel_switchCamera => 'Alternar câmera';

  @override
  String get callThumbnail_SemanticsAction_moveTopLeft => 'Mover para o canto superior esquerdo';

  @override
  String get callThumbnail_SemanticsAction_moveTopRight => 'Mover para o canto superior direito';

  @override
  String get callThumbnail_SemanticsAction_moveMiddleLeft => 'Mover para o meio à esquerda';

  @override
  String get callThumbnail_SemanticsAction_moveMiddleRight => 'Mover para o meio à direita';

  @override
  String get callThumbnail_SemanticsAction_moveBottomLeft => 'Mover para o canto inferior esquerdo';

  @override
  String get callThumbnail_SemanticsAction_moveBottomRight => 'Mover para o canto inferior direito';

  @override
  String get callThumbnail_SemanticsLabel_returnToCall => 'Voltar para a chamada';

  @override
  String callTile_SemanticsLabel_call(String name) {
    return 'Ligar para $name';
  }

  @override
  String callTile_SemanticsLabel_videoCall(String name) {
    return 'Chamada de vídeo para $name';
  }

  @override
  String get callerId_SemanticsLabel_addMatch => 'Adicionar uma regra de código de discagem';

  @override
  String get callerId_SemanticsLabel_matchNumber => 'Número a exibir para este código de discagem';

  @override
  String get callerId_SemanticsLabel_defaultNumber => 'Número usado por padrão para ligar';

  @override
  String callerId_SemanticsLabel_matchPrefix(String country) {
    return 'Código de discagem da regra, atualmente $country';
  }

  @override
  String callerId_SemanticsLabel_removeMatch(String dialCode) {
    return 'Remover a regra para $dialCode';
  }

  @override
  String callerId_SemanticsLabel_matchRule(String dialCode, String number) {
    return 'Chamadas para $dialCode exibem $number';
  }

  @override
  String callerId_SemanticsLabel_matchRuleWithCountry(String dialCode, String country, String number) {
    return 'Chamadas para $dialCode, $country, exibem $number';
  }

  @override
  String get call_CallActionsTooltip_accept => 'Aceitar';

  @override
  String get call_CallActionsTooltip_accept_inviteToAttendedTransfer => 'Aceitar transferência';

  @override
  String get call_CallActionsTooltip_attended_transfer => 'Transferência assistida';

  @override
  String get call_CallActionsTooltip_unattendedTransferHint => 'Passar a chamada sem falar antes';

  @override
  String get call_CallActionsTooltip_attendedTransferHint => 'Falar com a pessoa primeiro e depois passar a chamada';

  @override
  String get call_CallActionsTooltip_transferToCallHint => 'Conectar a pessoa a esta chamada';

  @override
  String get call_CallActionsTooltip_transferChooseHint => 'Transferir a chamada para outro número';

  @override
  String get call_CallActionsTooltip_addParticipantHint => 'Ligar para alguém e incluir nesta chamada';

  @override
  String get call_CallActionsTooltip_addParticipantHint_conference => 'Ligar para alguém e incluir na conferência';

  @override
  String get call_CallActionsTooltip_cancelInviteHint => 'Parar de chamar e voltar para a chamada';

  @override
  String get call_CallActionsTooltip_cancelInviteHint_conference => 'Parar de chamar e voltar para a conferência';

  @override
  String get call_CallActionsTooltip_addOrTransfer => 'Adicionar ou transferir';

  @override
  String get call_CallActionsTooltip_addParticipant => 'Adicionar participante';

  @override
  String call_CallActionsTooltip_cancelInvite(String name) {
    return 'Cancelar o convite para $name';
  }

  @override
  String get call_CallActionsTooltip_changeAudioDevice => 'Alterar dispositivo de áudio';

  @override
  String get call_CallActionsTooltip_decline_inviteToAttendedTransfer => 'Recusar transferência';

  @override
  String get call_CallActionsTooltip_device_bluetooth => 'Bluetooth';

  @override
  String get call_CallActionsTooltip_device_earpiece => 'Fone do aparelho';

  @override
  String get call_CallActionsTooltip_device_speaker => 'Alto-falante';

  @override
  String get call_CallActionsTooltip_device_streaming => 'Streaming';

  @override
  String get call_CallActionsTooltip_device_unknown => 'Dispositivo desconhecido';

  @override
  String get call_CallActionsTooltip_device_wiredHeadset => 'Fone de ouvido com fio';

  @override
  String get call_CallActionsTooltip_disableCamera => 'Desativar câmera';

  @override
  String get call_CallActionsTooltip_disableSpeaker => 'Desativar viva-voz';

  @override
  String get call_CallActionsTooltip_enableCamera => 'Ativar câmera';

  @override
  String get call_CallActionsTooltip_cameraPermissionDenied =>
      'Permissão da câmera negada. Toque para abrir as configurações';

  @override
  String get call_CallActionsTooltip_enableSpeaker => 'Ativar viva-voz';

  @override
  String get call_CallActionsTooltip_hangup => 'Desligar';

  @override
  String get call_CallActionsTooltip_hideKeypad => 'Ocultar teclado';

  @override
  String get call_CallActionsTooltip_hold => 'Colocar chamada em espera';

  @override
  String get call_CallActionsTooltip_mute => 'Silenciar microfone';

  @override
  String get call_CallActionsTooltip_showKeypad => 'Mostrar teclado';

  @override
  String get call_CallActionsTooltip_transfer => 'Transferir';

  @override
  String get call_CallActionsTooltip_transfer_choose => 'Escolher número';

  @override
  String get call_CallActionsTooltip_unattended_transfer => 'Transferência direta';

  @override
  String get call_CallActionsTooltip_unhold => 'Retomar chamada';

  @override
  String get call_CallActionsTooltip_unmute => 'Ativar microfone';

  @override
  String get call_CallList_incoming => 'Recebida';

  @override
  String get call_CallList_outgoing => 'Efetuada';

  @override
  String get conferenceRefusal_conferenceDisabled => 'Conferências não estão disponíveis nesta conta';

  @override
  String get conferenceRefusal_conferenceAlreadyActive => 'Já existe uma conferência em andamento';

  @override
  String get conferenceRefusal_lineAlreadyInConference => 'Essa chamada já está na conferência';

  @override
  String get conferenceRefusal_callsAreGone => 'Essas chamadas não estão mais disponíveis para unir';

  @override
  String get conferenceRefusal_lineNotReady => 'Esse participante ainda está entrando';

  @override
  String get conferenceRefusal_unavailable => 'Não foi possível unir as chamadas';

  @override
  String get call_CallList_add => 'Adicionar';

  @override
  String get call_SemanticsLabel_add => 'Adicionar as chamadas à conferência';

  @override
  String get call_Text_addParticipantNoFreeLine => 'Todas as linhas estão ocupadas';

  @override
  String call_CallList_outsideHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chamadas fora da conferência',
      one: '$count chamada fora da conferência',
    );
    return '$_temp0';
  }

  @override
  String call_ConferencePanel_header(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conferência - $count participantes',
      one: 'Conferência - $count participante',
    );
    return '$_temp0';
  }

  @override
  String get call_ConferencePanel_you => 'Você';

  @override
  String get call_ConferencePanel_hostStatus => 'Anfitrião';

  @override
  String get call_ConferencePanel_hostStatusAside => 'Em outra chamada';

  @override
  String get call_ConferencePanel_parkedNote => 'Você está em outra chamada';

  @override
  String get call_ConferencePanel_participantStatus => 'Na conferência';

  @override
  String get call_ConferencePanel_participantMuted => 'Silenciado para todos';

  @override
  String get call_ConferencePanel_end => 'Encerrar';

  @override
  String get call_ConferenceFullScreen_switchCamera => 'Alternar câmera';

  @override
  String call_ConferenceFullScreen_participantLeft(String name) {
    return '$name saiu da conferência';
  }

  @override
  String call_ConferenceFullScreen_title(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conferência · $count participantes',
      one: 'Conferência · $count participante',
    );
    return '$_temp0';
  }

  @override
  String call_ConferenceFullScreen_sharing(String name) {
    return '$name está compartilhando a tela';
  }

  @override
  String get call_ConferenceFullScreen_holdUnavailable => 'A espera não está disponível em uma conferência';

  @override
  String get call_ConferenceFullScreen_showLarge => 'Mostrar em tamanho grande';

  @override
  String call_SemanticsLabel_conferenceParticipantMenu(String name) {
    return 'Mais opções para $name';
  }

  @override
  String get call_SemanticsLabel_conferenceFullScreen => 'Mostrar a conferência em tela cheia';

  @override
  String call_SemanticsLabel_conferenceParticipantMute(String name) {
    return 'Silenciar $name para todos';
  }

  @override
  String call_SemanticsLabel_conferenceParticipantUnmute(String name) {
    return 'Reativar o som de $name para todos';
  }

  @override
  String call_SemanticsLabel_conferenceParticipantHangup(String name) {
    return 'Encerrar a chamada com $name';
  }

  @override
  String get call_SemanticsLabel_conferenceEnd => 'Encerrar a conferência e todas as chamadas dela';

  @override
  String get call_CallList_merge => 'Unir';

  @override
  String get call_SemanticsLabel_merge => 'Unir as chamadas em uma conferência';

  @override
  String call_CallList_header(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chamadas - toque para escolher',
      one: '$count chamada - toque para escolher',
    );
    return '$_temp0';
  }

  @override
  String get call_CallList_statusOnCall => 'Em chamada';

  @override
  String call_FocusedActionHint_actingOn(String name) {
    return 'Ação sobre: $name';
  }

  @override
  String call_FocusedActionHint_willBeEnded(String name) {
    return 'A chamada com $name será encerrada';
  }

  @override
  String call_FocusedActionHint_willBeHeld(String name) {
    return 'A chamada com $name será colocada em espera';
  }

  @override
  String get call_ToolbarStatus_connecting => 'Conectando...';

  @override
  String call_SemanticsLabel_noiseReductionOff(String action) {
    return '$action. A redução de ruído está desativada';
  }

  @override
  String get call_ToolbarStatus_noiseReductionOff => 'A redução de ruído está desativada';

  @override
  String get call_ToolbarStatus_reconnecting => 'Reconectando...';

  @override
  String get call_Watch_more => 'Mais';

  @override
  String get call_Watch_mute => 'Silenciar';

  @override
  String get call_Watch_speaker => 'Viva-voz';

  @override
  String get call_Watch_audio => 'Áudio';

  @override
  String get call_Watch_keypad => 'Teclado';

  @override
  String get call_Watch_hold => 'Espera';

  @override
  String get call_Watch_resume => 'Retomar';

  @override
  String get call_Watch_transfer => 'Transferir';

  @override
  String get call_Watch_camera => 'Câmera';

  @override
  String get call_Watch_switchCamera => 'Alternar';

  @override
  String get call_Watch_blur => 'Desfoque';

  @override
  String get call_Watch_calls => 'Chamadas';

  @override
  String get call_Watch_conference => 'Grupo';

  @override
  String get call_Watch_drop => 'Desligar';

  @override
  String get call_description_held => 'Em espera';

  @override
  String get call_description_peerReportsMuted => 'O outro lado informa que você está sem som';

  @override
  String get call_description_peerReportsHostAway => 'O outro lado informa que está em outra chamada';

  @override
  String get call_description_incoming => 'Chamada recebida';

  @override
  String get call_description_inviteToAttendedTransfer =>
      'Você foi convidado a participar de uma chamada de transferência assistida';

  @override
  String get call_description_outgoing => 'Chamada efetuada';

  @override
  String get call_description_requestToAttendedTransfer => 'Solicitação de transferência';

  @override
  String get call_description_transferProcessing => 'Processando transferência';

  @override
  String get call_errorRegisteringSelfManagedPhoneAccount =>
      'Ocorreu um problema ao registrar a conta telefônica autogerenciada.';

  @override
  String get call_FailureAcknowledgeDialog_title => 'Falha';

  @override
  String get callProcessingStatus_answering => 'Atendendo a chamada, aguarde…';

  @override
  String get callProcessingStatus_disconnecting => 'Encerrando a chamada, aguarde…';

  @override
  String get callProcessingStatus_init_media => 'Inicializando dispositivos de mídia';

  @override
  String get callProcessingStatus_invite => 'Estabelecendo a sessão SIP';

  @override
  String get callProcessingStatus_preparing => 'Preparando';

  @override
  String get callProcessingStatus_ringing => 'Chamando';

  @override
  String get callProcessingStatus_routing => 'Encaminhando a chamada';

  @override
  String get callProcessingStatus_signaling_connecting => 'Conectando ao servidor remoto';

  @override
  String get iceConnectionIssue_iceFail => 'Falha na conexão de mídia. Verifique sua rede';

  @override
  String get iceConnectionIssue_iceFailNoIcePath => 'Falha na conexão de mídia. Tente mudar para outra rede';

  @override
  String get iceConnectionIssue_iceFailNoIcePathViaVpn => 'A VPN pode estar bloqueando a chamada. Tente desativá-la';

  @override
  String get callNetworkQuality_yourAudioWeak => 'Seu áudio está fraco';

  @override
  String get callNetworkQuality_yourVideoWeak => 'Seu vídeo está fraco';

  @override
  String get callNetworkQuality_theirAudioWeak => 'O áudio do outro lado está fraco';

  @override
  String get callNetworkQuality_theirVideoWeak => 'O vídeo do outro lado está fraco';

  @override
  String get callPullBadge_dialogTitle => 'Chamadas que podem ser puxadas';

  @override
  String get callPullBadge_pickupButtonTitle => 'Atender';

  @override
  String get call_settings_additional_options => 'Opções adicionais';

  @override
  String get callStatus_appUnregistered => 'Sem registro';

  @override
  String get callStatus_connectError => 'Erro de conexão';

  @override
  String get callStatus_connectIssue => 'Problema de conexão';

  @override
  String get callStatus_connectivityNone => 'Sem conexão com a internet';

  @override
  String get callStatus_inProgress => 'Conexão em andamento';

  @override
  String get callStatus_ready => 'Conexão estabelecida';

  @override
  String get call_SystemErrorDialog_description =>
      'Para voltar a fazer chamadas, é necessário reiniciar o telefone. Isso resolverá um erro temporário do sistema.';

  @override
  String get callStatus_serviceUnavailable => 'Serviço temporariamente indisponível';

  @override
  String get call_SystemErrorDialog_title => 'Erro do sistema';

  @override
  String get call_ScreenShareTile_title => 'Compartilhando a tela';

  @override
  String get call_ScreenShareTile_stop => 'Parar';

  @override
  String get call_ConferenceFullScreen_screenWaiting => 'Aguardando a tela';

  @override
  String get call_screenShare_actionLabel_share => 'Compartilhar tela';

  @override
  String get call_screenShare_actionLabel_stop => 'Parar compartilhamento';

  @override
  String get call_ThumbnailAvatar_currentlyNoActiveCall => 'No momento, não há chamada ativa';

  @override
  String get call_videoBackground_actionLabel_disableBlur => 'Desativar desfoque';

  @override
  String get call_videoBackground_actionLabel_enableBlur => 'Ativar desfoque';

  @override
  String get call_videoView_actionLabel_cover => 'Preencher';

  @override
  String get call_videoView_actionLabel_fit => 'Ajustar';

  @override
  String get cdrs_noMissedCalls_message => 'Nenhuma chamada perdida';

  @override
  String get cdrs_noRecentCalls_message => 'Nenhuma chamada recente';

  @override
  String get cdrs_refreshFailed_message => 'Não foi possível atualizar o histórico de chamadas - tente novamente';

  @override
  String get common_Watch_openOnPhone_message => 'Abre no seu telefone';

  @override
  String get common_Watch_openOnPhone_hint => 'Leia no telefone pareado';

  @override
  String get common_Watch_openOnPhone_action => 'Abrir no telefone';

  @override
  String get common_Watch_openOnPhone_sent => 'Confira seu telefone';

  @override
  String get common_Watch_openOnPhone_sentHint => 'A página está aberta lá';

  @override
  String get common_Watch_openOnPhone_failed => 'Nenhum telefone conectado';

  @override
  String get common_Watch_openOnPhone_failedHint => 'Conecte o telefone e tente novamente';

  @override
  String get common_Watch_openOnPhone_retry => 'Tentar novamente';

  @override
  String get common_Watch_phoneOnly => 'Abra no app do seu telefone';

  @override
  String get common_SemanticsLabel_loading => 'Carregando';

  @override
  String get common_noInternetConnection_message =>
      'Parece que você não está conectado à internet. Verifique sua conexão e tente novamente.';

  @override
  String get common_noInternetConnection_retryButton => 'Tentar novamente';

  @override
  String get common_noInternetConnection_title => 'Sem conexão com a internet';

  @override
  String get common_problemWithLoadingPage => 'Ocorreu um problema ao carregar a página.';

  @override
  String contact_SemanticsLabel_addFavorite(String number) {
    return 'Adicionar $number aos favoritos';
  }

  @override
  String contact_SemanticsLabel_optionInfo(String option) {
    return 'O que significa $option';
  }

  @override
  String contact_SemanticsLabel_removeFavorite(String number) {
    return 'Remover $number dos favoritos';
  }

  @override
  String contact_SemanticsLabel_sendEmail(String address) {
    return 'Enviar um e-mail para $address';
  }

  @override
  String contact_SemanticsLabel_transfer(String number) {
    return 'Transferir a chamada atual para $number';
  }

  @override
  String contact_SemanticsLabel_addParticipant(String number) {
    return 'Adicionar $number à chamada';
  }

  @override
  String contact_SemanticsLabel_attendedTransfer(String number) {
    return 'Consultar $number antes de transferir a chamada';
  }

  @override
  String get contacts_ContactsScreen_emptyFavorites =>
      'Ainda não há favoritos entre seus contatos.\nAdicione um pelo cartão do contato usando o ícone de estrela';

  @override
  String get contacts_ContactsScreen_searchSemanticsLabel => 'Pesquisar contatos';

  @override
  String get contacts_ContactsScreen_sourceSemanticsLabel => 'Origem dos contatos';

  @override
  String get contacts_agreement_button_text => 'Continuar';

  @override
  String get contacts_agreement_checkbox_text =>
      'Concordo em permitir que o app acesse meus contatos para melhorar minha experiência de uso.';

  @override
  String get contacts_agreement_toggle_text => 'Permitir acesso aos contatos';

  @override
  String get contacts_agreement_description =>
      'Com a sua permissão, o app mostra os contatos do seu telefone na aba Contatos. Você pode compartilhar todos ou apenas os que escolher. \n\nOs dados dos contatos são armazenados temporariamente no seu dispositivo para permitir recursos como fazer chamadas diretamente pelo app. \n\nEsses dados não são coletados, transmitidos nem compartilhados fora do app.';

  @override
  String get contacts_agreement_title => 'Coleta de dados';

  @override
  String get contacts_DestinationNumberPicker_title => 'Escolha um número para ligar';

  @override
  String get contacts_ExternalTabButton_refresh => 'Atualizar';

  @override
  String get contacts_ExternalTabSnackBar_requestFailed => 'Não foi possível acessar o servidor - tente novamente';

  @override
  String get contacts_ExternalTabText_empty => 'Nenhum contato';

  @override
  String get contacts_ExternalTabText_emptyOnSearching => 'Nenhum contato encontrado';

  @override
  String get contacts_ExternalTabText_failure => 'Falha ao obter os contatos do PABX em nuvem';

  @override
  String get contacts_LocalTabButton_changeSelection => 'Alterar seleção';

  @override
  String get contacts_LocalTabButton_contactsAgreement => 'Abrir Configurações';

  @override
  String get contacts_LocalTabButton_openAppSettings => 'Conceder acesso aos contatos do telefone';

  @override
  String get contacts_LocalTabButton_refresh => 'Atualizar';

  @override
  String get contacts_LocalTabText_contactsAgreementFailure =>
      'Para sincronizar seus contatos locais, você precisa aceitar o acordo nas Configurações.';

  @override
  String get contacts_LocalTabText_empty => 'Nenhum contato';

  @override
  String get contacts_LocalTabText_emptyOnSearching => 'Nenhum contato encontrado';

  @override
  String get contacts_LocalTabText_failure => 'Falha ao obter os contatos do seu telefone';

  @override
  String get contacts_LocalTabText_permissionFailure => 'Não há permissão para obter os contatos do seu telefone';

  @override
  String get contactsSourceFavorites => 'Favoritos';

  @override
  String get contactsSourceExternal => 'PABX em nuvem';

  @override
  String get contactsSourceLocal => 'Seu telefone';

  @override
  String get contacts_LocalTabText_selectionOnly => 'Apenas os contatos que você selecionou são exibidos';

  @override
  String get contacts_LocalTabText_selectionOnlyEmpty =>
      'Apenas os contatos selecionados são exibidos, e nenhum foi selecionado ainda';

  @override
  String get contacts_DialogsInfoView_title => 'Informações de chamadas (BLF):';

  @override
  String contacts_ContactTile_inCall(Object destination) {
    return 'Em chamada: $destination';
  }

  @override
  String get contacts_ContactScreen_options => 'Opções:';

  @override
  String get contacts_ContactScreen_presenceViaSip => 'Assinar o status do usuário via SIP (Presence)';

  @override
  String get contacts_ContactScreen_presenceViaSip_tooltip =>
      'Além da troca direta de dados (de app para app), a assinatura pelo recurso SIP-Presence permite obter informações de presença de outros agentes de usuário (telefones de mesa, softphones independentes etc.). Recomenda-se ativar somente se o seu contato prefere usar agentes de usuário legados e você quer ver o status de presença dele em todos os dispositivos.';

  @override
  String get contacts_ContactScreen_dialogsViaSipBlf => 'Assinar as chamadas ativas via SIP (BLF/Dialogs)';

  @override
  String get contacts_ContactScreen_dialogsViaSipBlf_tooltip =>
      'Além da troca direta de dados (de app para app), a assinatura pelo recurso SIP-Dialogs permite obter informações do estado das chamadas de outros agentes de usuário (telefones de mesa, softphones independentes etc.). Recomenda-se ativar somente se o seu contato prefere usar agentes de usuário legados e você quer ver o status das chamadas dele em todos os dispositivos.';

  @override
  String get copyToClipboard_floatingSnackBar => 'Texto copiado';

  @override
  String get copyToClipboard_popupMenuItem => 'Copiar para a área de transferência';

  @override
  String get database_Cache_description =>
      'Cópia armazenada localmente dos dados obtidos do servidor: histórico de chamadas, lista do correio de voz, conversas e contatos. A limpeza remove todos os registros locais; cada recurso baixa seus dados novamente na próxima sincronização.';

  @override
  String get database_Cache_title => 'Banco de dados local';

  @override
  String get default_CannotRemoveOwnerMessagingSocketException => 'Não é possível remover o proprietário';

  @override
  String get default_ChatMemberNotFoundMessagingSocketException => 'Membro da conversa não encontrado';

  @override
  String get default_ChatNotFoundMessagingSocketException => 'Conversa não encontrada';

  @override
  String get default_ClientExceptionError => 'Ocorreu um problema no cliente HTTP';

  @override
  String get default_ErrorDetails => 'Detalhes';

  @override
  String get default_ErrorMessage => 'Mensagem de erro';

  @override
  String get default_ErrorPath => 'Caminho do erro';

  @override
  String get default_ErrorTransactionId => 'ID da transação';

  @override
  String get default_ForbiddenMessagingSocketException => 'Solicitação proibida';

  @override
  String get default_FormatExceptionError => 'Ocorreu um problema no formato da resposta';

  @override
  String get default_InternalErrorMessagingSocketException => 'Erro interno do servidor';

  @override
  String get default_InvalidChatTypeMessagingSocketException => 'Tipo de conversa inválido';

  @override
  String get default_JoinCrashedMessagingSocketException => 'Ocorreu um erro ao entrar na conversa';

  @override
  String get default_MessagingSocketException => 'Ocorreu um erro ao processar a solicitação';

  @override
  String get default_RequestFailureError => 'Ocorreu uma falha no servidor';

  @override
  String get default_SelfAuthorityAssignmentForbiddenMessagingSocketException =>
      'Não é permitido atribuir permissões a si mesmo';

  @override
  String get default_SelfRemovalForbiddenMessagingSocketException => 'Não é permitido remover a si mesmo';

  @override
  String get default_SmsConversationNotFoundMessagingSocketException => 'Conversa de SMS não encontrada';

  @override
  String get default_TimeoutExceptionError => 'O tempo limite do servidor foi excedido';

  @override
  String get default_TimeoutMessagingSocketException => 'O tempo limite da solicitação foi excedido';

  @override
  String get default_TlsExceptionError => 'Ocorreu um problema no protocolo de rede seguro (TLS/SSL)';

  @override
  String get default_TypeErrorError => 'Ocorreu um problema na resposta';

  @override
  String get default_UnauthorizedMessagingSocketException => 'Solicitação não autorizada';

  @override
  String get default_UnauthorizedRequestFailureError => 'Ocorreu uma falha de solicitação não autorizada';

  @override
  String default_UnknownExceptionError(String error) {
    return 'Ocorreu um problema desconhecido: $error';
  }

  @override
  String get default_UserAlreadyInChatMessagingSocketException => 'O usuário já está na conversa';

  @override
  String get diagnostic_AppBar_title => 'Diagnóstico';

  @override
  String get diagnostic_battery_groupTitle => 'Bateria';

  @override
  String get diagnostic_batteryMode_optimized_description =>
      'A atividade do app em segundo plano é gerenciada pelo sistema para economizar bateria. Ele pode não funcionar corretamente com chamadas recebidas acionadas por notificações push.';

  @override
  String get diagnostic_batteryMode_optimized_title => 'Otimizado';

  @override
  String get diagnostic_batteryMode_restricted_description =>
      'A atividade do app em segundo plano é fortemente restringida para economizar bateria. Chamadas recebidas podem ser perdidas.';

  @override
  String get diagnostic_batteryMode_restricted_title => 'Restrito';

  @override
  String get diagnostic_batteryMode_unknown_description =>
      'O status do modo de bateria é desconhecido. O app pode ter um comportamento imprevisível.';

  @override
  String get diagnostic_batteryMode_unknown_title => 'Desconhecido';

  @override
  String get diagnostic_batteryMode_unrestricted_description =>
      'O app tem acesso total para ser executado em segundo plano sem restrições.';

  @override
  String get diagnostic_batteryMode_unrestricted_title => 'Sem restrições';

  @override
  String get diagnostic_battery_navigate_section => 'Ir para a seção Bateria';

  @override
  String get diagnostic_battery_tile_title => 'Modo de bateria';

  @override
  String get diagnostic_callingMode_groupTitle => 'Modo de chamada';

  @override
  String get diagnostic_callingMode_tile_title => 'Modo de chamada';

  @override
  String get diagnostic_callingMode_standalone_title => 'Modo de chamada limitado';

  @override
  String get diagnostic_callingMode_standalone_caption =>
      'Independente - o toque e a seleção de fone podem ser limitados';

  @override
  String get diagnostic_callingMode_standalone_description =>
      'Este dispositivo não oferece suporte ao framework de chamadas do sistema (Telecom), por isso as chamadas recebidas usam um serviço limitado em segundo plano. As chamadas podem atrasar ou ser perdidas quando o sistema restringe apps em segundo plano. A seleção de fone Bluetooth e com fio não está disponível neste modo.';

  @override
  String get diagnostic_fullScreenIntent_tile_title => 'Chamadas em tela cheia';

  @override
  String get diagnostic_fullScreenIntent_navigate_section => 'Ir para a seção de notificações em tela cheia';

  @override
  String get diagnostic_fullScreenIntent_groupTitle => 'Chamadas na tela de bloqueio';

  @override
  String get diagnostic_fullScreenIntent_caption => 'As chamadas chegam como notificação, não em tela cheia';

  @override
  String get diagnostic_fullScreenIntent_description =>
      'Permite que uma chamada recebida abra em tela cheia sobre a tela de bloqueio e seja atendida ali mesmo. Sem isso, a chamada chega como notificação, e atender em uma tela bloqueada protegida por PIN, padrão ou impressão digital exige desbloquear o telefone primeiro.';

  @override
  String get diagnostic_permission_camera_description =>
      'Este app precisa de permissão para acessar a câmera para fazer chamadas de vídeo.';

  @override
  String get diagnostic_permission_camera_title => 'Câmera';

  @override
  String get diagnostic_permission_contacts_description =>
      'Os contatos que você compartilha são exibidos no app, para que você possa ligar para eles e ver quem está ligando. Compartilhar uma seleção de contatos é suficiente.';

  @override
  String get diagnostic_permission_contacts_title => 'Contatos';

  @override
  String get diagnostic_Watch_openSettings => 'Abrir configurações';

  @override
  String get diagnostic_Watch_allow => 'Permitir';

  @override
  String get diagnostic_Watch_runAgain => 'Executar novamente';

  @override
  String get diagnosticPermissionDetails_button_managePermission => 'Gerenciar permissão';

  @override
  String get diagnosticPermissionDetails_button_requestPermission => 'Solicitar permissão';

  @override
  String get diagnosticPermissionDetails_title_statusPermission => 'Status da permissão';

  @override
  String get diagnostic_permission_microphone_description =>
      'Este app precisa de permissão para acessar o microfone para fazer chamadas de áudio.';

  @override
  String get diagnostic_permission_microphone_title => 'Microfone';

  @override
  String get diagnostic_permission_notification_description => 'Permite que o app apresente chamadas recebidas.';

  @override
  String get diagnostic_permission_notification_title => 'Notificação';

  @override
  String get diagnostic_permissionStatus_denied => 'Acesso negado';

  @override
  String get diagnostic_permissionStatus_granted => 'Acesso concedido';

  @override
  String get diagnostic_permissionStatus_limited => 'Acesso limitado';

  @override
  String get diagnostic_permissionStatus_permanentlyDenied => 'Acesso negado permanentemente';

  @override
  String get diagnostic_permissionStatus_provisional => 'Acesso provisório';

  @override
  String get diagnostic_permissionStatus_restricted => 'Acesso restrito';

  @override
  String get diagnostic_specialPermissionStatus_denied => 'Acesso negado';

  @override
  String get diagnostic_specialPermissionStatus_granted => 'Acesso concedido';

  @override
  String get diagnostic_specialPermissionStatus_unknown => 'Desconhecido';

  @override
  String get diagnostic_xiaomi_backgroundActivityStart_description =>
      'O MIUI/HyperOS restringe a exibição da tela de chamada recebida enquanto o app é executado em segundo plano, a menos que a permissão \"Exibir janelas pop-up durante a execução em segundo plano\" seja concedida a este app.';

  @override
  String get diagnostic_xiaomi_backgroundActivityStart_tile_title =>
      'Exibir janelas pop-up durante a execução em segundo plano';

  @override
  String get diagnostic_xiaomi_groupTitle => 'Permissões da Xiaomi';

  @override
  String get diagnostic_xiaomi_navigate_section => 'Ir para a seção de permissões da tela de bloqueio';

  @override
  String get diagnostic_xiaomi_showWhenLocked_description =>
      'O MIUI/HyperOS restringe a exibição da tela de chamada recebida sobre a tela de bloqueio, a menos que a permissão \"Mostrar na tela de bloqueio\" seja concedida a este app.';

  @override
  String get diagnostic_xiaomi_showWhenLocked_tile_title => 'Mostrar na tela de bloqueio';

  @override
  String get diagnosticPushDetails_configuration_title => 'Configuração do serviço de notificações push';

  @override
  String get diagnosticPushDetails_errorMessage_intro => 'Algumas etapas para tentar:\n';

  @override
  String get diagnosticPushDetails_errorMessage_step1 => '1. Verifique se o telefone está conectado à internet.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step2 =>
      '2. Se estiver conectado, verifique se o telefone consegue acessar os serviços do Google visitando um site.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step3 =>
      '3. Aguarde alguns minutos e tente novamente – os servidores de mensagens do Firebase podem estar temporariamente fora do ar.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step4 =>
      '4. Reinicie o Google Play Services para garantir que esteja funcionando corretamente.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step5 =>
      '5. Verifique se o Google Play Services está instalado no seu dispositivo.\n';

  @override
  String get diagnosticPushDetails_successMessage =>
      'O serviço de notificações foi configurado com sucesso e está pronto para receber mensagens e tratar chamadas recebidas.';

  @override
  String get diagnostic_pushTokenStatusType_progress => 'Em andamento';

  @override
  String get diagnostic_pushTokenStatusType_success => 'Serviço configurado com sucesso';

  @override
  String get diagnosticReportDialogAddNoteExpansionTileTitle => 'Adicionar uma observação (opcional)';

  @override
  String get diagnosticReportDialogCancelButtonLabel => 'Cancelar';

  @override
  String get diagnosticReportDialogCommentTextFieldHintText => 'Descreva o que aconteceu...';

  @override
  String get diagnosticReportDialogContent =>
      'Este relatório contém detalhes técnicos que nos ajudam a identificar problemas de conexão.';

  @override
  String get diagnosticReportDialogIncludeSystemLogsSwitchTileSubtitle => 'Requer permissões adicionais.';

  @override
  String get diagnosticReportDialogIncludeSystemLogsSwitchTileTitle => 'Incluir logs do sistema';

  @override
  String get diagnosticReportDialogSendReportButtonLabel => 'Enviar relatório';

  @override
  String get diagnosticReportDialogTitle => 'Enviar relatório de diagnóstico';

  @override
  String get diagnosticScreen_contacts_agreement_description =>
      'Permitir que o app acesse meus contatos para melhorar minha experiência de uso.';

  @override
  String get diagnosticScreen_contacts_agreement_group_title => 'Acordo';

  @override
  String get diagnosticScreen_contacts_agreement_title => 'Acordo de contatos';

  @override
  String get diagnosticScreen_permissionsGroup_title => 'Permissões';

  @override
  String get diagnosticScreen_pushNotificationService_title => 'Serviço de notificações push';

  @override
  String get diagnostic_network_groupTitle => 'Rede';

  @override
  String get diagnosticNetworkTest_status_offline => 'Offline';

  @override
  String get diagnosticNetworkTest_status_reachable => 'Acessível';

  @override
  String get diagnosticNetworkTest_status_restricted => 'Restrito';

  @override
  String get diagnosticNetworkTest_status_checking => 'Verificando…';

  @override
  String get diagnosticNetworkTest_status_unreachable => 'Inacessível';

  @override
  String get diagnosticNetworkTestItem_subtitle_noNetwork => 'Sem conexão de rede';

  @override
  String diagnosticNetworkTestItem_subtitle_publicIps(String ips) {
    return 'Público: $ips';
  }

  @override
  String get diagnosticNetworkTestItem_subtitle_stunBlocked => 'STUN bloqueado · relay disponível';

  @override
  String get diagnosticNetworkTestItem_subtitle_stunUnreachable => 'STUN inacessível · somente local';

  @override
  String get diagnosticNetworkTestItem_subtitle_noCandidates => 'Nenhum candidato ICE coletado';

  @override
  String get diagnosticNetworkTestItem_network_wifi => 'WiFi';

  @override
  String get diagnosticNetworkTestItem_network_mobile => 'Rede móvel';

  @override
  String get diagnosticNetworkTestItem_network_ethernet => 'Ethernet';

  @override
  String get diagnosticNetworkTestItem_network_vpn => 'VPN';

  @override
  String get diagnosticNetworkTestDetails_title => 'Acessibilidade da rede';

  @override
  String get diagnosticNetworkTestDetails_description =>
      'Verifica se o seu dispositivo consegue fazer e receber chamadas pela internet testando a conectividade de rede.\nCandidatos server-reflexive (srflx) confirmam que um IP público é acessível via STUN. Candidatos relay significam que o acesso direto está bloqueado e que é necessário um servidor TURN. Somente host significa que o STUN está inacessível e que só conexões locais são possíveis.';

  @override
  String get diagnosticNetworkTestDetails_status => 'Status';

  @override
  String get diagnosticNetworkTestDetails_candidates => 'Candidatos';

  @override
  String get diagnosticNetworkTestDetails_noNetwork => 'Sem conexão de rede';

  @override
  String get diagnosticNetworkTestDetails_noCandidates => 'Nenhum candidato ICE coletado';

  @override
  String get favorites_BodyCenter_empty =>
      'No momento, você não tem números favoritos.\nAdicione favoritos em Contatos usando o ícone de estrela';

  @override
  String get favorites_DeleteConfirmDialog_content => 'Tem certeza de que deseja excluir este número favorito?';

  @override
  String get favorites_DeleteConfirmDialog_title => 'Confirmar exclusão';

  @override
  String get favorites_SemanticsLabel_reorderDone => 'Concluir reordenação';

  @override
  String get favorites_SemanticsLabel_reorder => 'Reordenar favoritos';

  @override
  String favorites_SnackBar_deleted(String name) {
    return '$name excluído';
  }

  @override
  String get favorites_Watch_empty => 'Ainda não há favoritos';

  @override
  String get favorites_Watch_emptyHint => 'Marque um contato com a estrela';

  @override
  String get favorites_Watch_notFound => 'Nenhum favorito encontrado';

  @override
  String get favorites_Watch_remove => 'Remover dos favoritos';

  @override
  String get favorites_Watch_removeQuestion => 'Remover dos favoritos?';

  @override
  String formatPhone(String style, String main, String ext) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'full': '$main (ramal: $ext)',
      'simple': '$main',
      'only_ext': 'ramal: $ext',
      'empty': 'Sem número de telefone',
      'other': '$main',
    });
    return '$_temp0';
  }

  @override
  String get locale_default => 'Padrão';

  @override
  String get locale_en => 'Inglês';

  @override
  String get locale_it => 'Italiano';

  @override
  String get locale_uk => 'Ucraniano';

  @override
  String get locale_th => 'Tailandês';

  @override
  String get locale_fr => 'Francês';

  @override
  String get locale_pt => 'Português';

  @override
  String get login_Button_coreUrlAssignProceed => 'Continuar';

  @override
  String get login_Button_otpSigninRequestProceed => 'Continuar';

  @override
  String get login_Button_otpSigninVerifyProceed => 'Verificar';

  @override
  String get login_Button_otpSigninVerifyRepeat => 'Reenviar o código';

  @override
  String login_Button_otpSigninVerifyRepeatInterval(int seconds) {
    return 'Reenviar o código ($seconds s)';
  }

  @override
  String get login_Button_passwordSigninProceed => 'Continuar';

  @override
  String get login_Button_signIn => 'Entrar';

  @override
  String get login_Button_signupRequestProceed => 'Continuar';

  @override
  String get login_Button_signUpToDemoInstance => 'Cadastrar-se / entrar';

  @override
  String get login_Button_signupVerifyProceed => 'Verificar';

  @override
  String get login_Button_signupVerifyRepeat => 'Reenviar o código';

  @override
  String login_Button_signupVerifyRepeatInterval(int seconds) {
    return 'Reenviar o código ($seconds s)';
  }

  @override
  String get login_ButtonTooltip_signInToYourInstance => 'Entrar no seu Cloud Backend';

  @override
  String get login_Button_customCoreShort => 'Cloud Backend';

  @override
  String login_CoreVersionUnsupportedExceptionError(String actual, String supportedConstraint) {
    return 'Foi informada uma versão de instância incompatível, entre em contato com o administrador do seu sistema (atual: $actual, suportada: $supportedConstraint)';
  }

  @override
  String login_AppVersionUnsupportedExceptionError(String actual, String minSupported) {
    return 'A versão do seu app não é mais suportada, atualize o aplicativo para continuar (atual: $actual, mínima exigida: $minSupported)';
  }

  @override
  String get login_RequestFailureAddonRequiredError =>
      'Sua conta não inclui acesso a este app. Entre em contato com seu provedor de serviços';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedError =>
      'Esta conta não tem um meio de contato configurado para receber o código de verificação';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedPhoneError =>
      'A conta com este número de telefone não tem um meio de contato configurado para receber o código de verificação';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedEmailError =>
      'A conta com este endereço de e-mail não tem um meio de contato configurado para receber o código de verificação';

  @override
  String get login_RequestFailureDeviceLimitReachedError =>
      'Limite de dispositivos atingido. Entre em contato com o administrador.';

  @override
  String get login_RequestFailureDeviceLimitStillReachedError =>
      'O limite de dispositivos continua atingido. Saia da conta em outro dispositivo.';

  @override
  String get login_RequestFailureDeviceSwitchLimitReachedError =>
      'Limite de trocas de dispositivo atingido. Entre em contato com o administrador.';

  @override
  String get login_RequestFailurePendingLoginNotFoundError => 'O login não foi concluído a tempo. Entre novamente.';

  @override
  String get login_RequestFailurePendingLoginSessionNotFoundError =>
      'Esse dispositivo já foi desconectado. Escolha outro.';

  @override
  String get login_RequestFailureEmptyEmailError => 'Não é possível enviar o código de verificação';

  @override
  String get login_RequestFailureIdentifierIsNotValid => 'O identificador é inválido ou não existe';

  @override
  String get login_RequestFailureIncorrectOtpCodeError => 'Código de verificação incorreto';

  @override
  String get login_RequestFailureOtpAlreadyVerifiedError => 'A verificação já foi concluída';

  @override
  String get login_RequestFailureOtpExpiredError => 'A verificação expirou';

  @override
  String get login_RequestFailureOtpNotFoundError => 'Verificação não encontrada';

  @override
  String get login_RequestFailureOtpVerificationAttemptsExceededError => 'Número de tentativas de verificação excedido';

  @override
  String get login_RequestFailureParametersApplyIssueError => 'Os dados informados não podem ser processados';

  @override
  String get login_RequestFailurePhoneNotFoundError => 'Número de telefone não encontrado';

  @override
  String get login_RequestFailureAmbiguousUserRefError =>
      'Várias contas usam este e-mail. Entre com o ID da sua conta (número de telefone).';

  @override
  String get login_RequestFailureIncorrectCredentialsError => 'Nome de usuário ou senha incorretos';

  @override
  String get login_RequestFailureUserNotFoundError => 'Usuário não encontrado';

  @override
  String get login_RequestFailureUnconfiguredBundleIdError => 'O app não é suportado pelo seu Cloud Backend';

  @override
  String get login_SemanticsLabel_hidePassword => 'Ocultar senha';

  @override
  String get login_SemanticsLabel_showPassword => 'Mostrar senha';

  @override
  String get login_SupportedLoginTypeMissedExceptionError =>
      'O Cloud Backend atual não oferece nenhum tipo de login compatível com este app';

  @override
  String login_Text_coreUrlAssignPostDescription(Object email) {
    return 'Se você ainda não tem seu próprio Cloud Backend - entre em contato com a equipe de vendas $email.';
  }

  @override
  String get login_Text_coreUrlAssignPreDescription =>
      'Para fazer chamadas pelo seu próprio sistema VoIP, informe abaixo a URL do seu Cloud Backend (conforme fornecida pelo seu gerente de conta).';

  @override
  String get login_TextFieldLabelText_coreUrlAssign => 'Informe a URL do seu Cloud Backend';

  @override
  String get login_TextFieldLabelText_coreUrlAssignShort => 'URL';

  @override
  String get login_TextFieldLabelText_otpSigninCode => 'Informe o código de verificação';

  @override
  String get login_TextFieldLabelText_otpSigninUserRef => 'Informe seu número de telefone ou e-mail';

  @override
  String get login_TextFieldLabelText_otpSigninUserRefPhone => 'Informe seu número de telefone';

  @override
  String get login_TextFieldLabelText_otpSigninUserRefEmail => 'Informe seu e-mail';

  @override
  String get login_TextFieldLabelText_passwordSigninPassword => 'Informe sua senha';

  @override
  String get login_TextFieldLabelText_passwordSigninUserRef => 'Informe seu número de telefone ou e-mail';

  @override
  String get login_TextFieldLabelText_signupCode => 'Informe o código de verificação';

  @override
  String get login_TextFieldLabelText_signupEmail => 'Informe seu e-mail';

  @override
  String get login_Text_deviceLimitDescription =>
      'Esta conta está conectada no número máximo de dispositivos permitido. Saia de um deles para continuar neste dispositivo.';

  @override
  String get login_Text_deviceLimitTitle => 'Limite de dispositivos atingido';

  @override
  String get login_Text_otpSigninRequestPostDescription => '';

  @override
  String get login_Text_otpSigninRequestPreDescription => '';

  @override
  String login_Text_otpSigninVerifyPostDescriptionFromEmail(String email) {
    return 'Se você não encontrar na caixa de entrada um e-mail de $email com o código de verificação, confira a pasta de spam.';
  }

  @override
  String get login_Text_otpSigninVerifyPostDescriptionGeneral =>
      'Se você não encontrar na caixa de entrada um e-mail com o código de verificação, confira a pasta de spam.';

  @override
  String login_Text_otpSigninVerifyPreDescriptionUserRef(String userRef) {
    return 'Um código de verificação de uso único foi enviado para o e-mail associado ao número de telefone ou e-mail informado.';
  }

  @override
  String get login_Text_passwordSigninPostDescription => '';

  @override
  String get login_Text_passwordSigninPreDescription => '';

  @override
  String get login_Text_signupRequestPostDescription => '';

  @override
  String get login_Text_signupRequestPostDescriptionDemo =>
      'Se você ainda não tem uma conta, ela será criada automaticamente';

  @override
  String get login_Text_signupRequestPreDescription => '';

  @override
  String get login_Text_signupRequestPreDescriptionDemo => '';

  @override
  String login_Text_signupVerifyPostDescriptionFromEmail(String email) {
    return 'Se você não encontrar na caixa de entrada um e-mail de $email com o código de verificação, confira a pasta de spam.';
  }

  @override
  String get login_Text_signupVerifyPostDescriptionGeneral =>
      'Se você não encontrar na caixa de entrada um e-mail com o código de verificação, confira a pasta de spam.';

  @override
  String login_Text_signupVerifyPreDescriptionEmail(String email) {
    return 'Um código de verificação de uso único foi enviado para $email.';
  }

  @override
  String get login_Text_qrSigninScanHint => 'Escaneie o código QR para entrar.';

  @override
  String get login_Text_qrSigninVerifyingTitle => 'Entrando...';

  @override
  String get login_Text_qrSigninVerifyingDescription => 'Código QR escaneado. Verificando com o servidor.';

  @override
  String get login_Text_qrSigninCameraPermissionTitle => 'O acesso à câmera está desativado';

  @override
  String get login_Text_qrSigninCameraPermissionDescription =>
      'O acesso à câmera é necessário para escanear um código QR. Ative-o para continuar.';

  @override
  String get login_Button_qrSigninAllowCameraAccess => 'Continuar';

  @override
  String get login_Button_qrSigninOpenSettings => 'Abrir configurações';

  @override
  String get login_Text_qrSigninInvalidCodeError => 'Este código QR não pode ser usado para entrar.';

  @override
  String get loginType_otpSigninShort => 'OTP';

  @override
  String get loginType_passwordSigninShort => 'Senha';

  @override
  String get loginType_signupShort => 'Cadastro';

  @override
  String get loginType_otpSignin => 'Login com OTP';

  @override
  String get loginType_passwordSignin => 'Login com senha';

  @override
  String get loginType_qrSignin => 'Código QR';

  @override
  String get loginType_signup => 'Cadastro';

  @override
  String get login_validationCoreUrlError => 'Informe uma URL válida';

  @override
  String get login_validationCoreUrlUnreachableError => 'Não foi possível acessar o serviço neste endereço';

  @override
  String get login_validationEmailError => 'Informe um e-mail válido';

  @override
  String get login_validationPhoneError => 'Informe um número de telefone válido';

  @override
  String get login_validationUserRefError => 'Informe um número de telefone ou e-mail válido';

  @override
  String get logRecordsConsole_AppBarTitle => 'Console de logs';

  @override
  String get logRecordsConsole_Button_failureRefresh => 'Atualizar';

  @override
  String get logRecordsConsole_Text_failure => 'Ocorreu um erro inesperado';

  @override
  String logRecordsConsole_Text_recordsCountHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exibindo os últimos $count registros. Use Compartilhar para exportar o log completo.',
      one: 'Exibindo $count registro. Use Compartilhar para exportar o log completo.',
    );
    return '$_temp0';
  }

  @override
  String get logRecordsConsole_Button_infoClose => 'Entendi';

  @override
  String get logRecordsConsole_PopupMenuItem_info => 'Informações';

  @override
  String get logRecordsConsole_PopupMenuItem_clear => 'Limpar';

  @override
  String get main_Button_cancelPicking => 'Cancelar';

  @override
  String get main_BottomNavigationBarItemLabel_callCenter => 'Call center';

  @override
  String get main_BottomNavigationBarItemLabel_chats => 'Conversas';

  @override
  String get main_Text_blindTransferInitiated => 'Realizando transferência direta';

  @override
  String get main_Text_addParticipantInitiated => 'Escolha quem adicionar à chamada';

  @override
  String get main_Text_attendedTransferInitiated => 'Escolha quem consultar antes de transferir';

  @override
  String get main_BottomNavigationBarItemLabel_contacts => 'Contatos';

  @override
  String get main_BottomNavigationBarItemLabel_favorites => 'Favoritos';

  @override
  String get main_BottomNavigationBarItemLabel_keypad => 'Teclado';

  @override
  String get main_BottomNavigationBarItemLabel_recents => 'Recentes';

  @override
  String get main_BottomNavigationBarItemLabel_voicemail => 'Correio de voz';

  @override
  String get main_Button_settings => 'Configurações';

  @override
  String get main_CompatibilityIssueDialogActions_logout => 'Sair';

  @override
  String get main_CompatibilityIssueDialogActions_update => 'Atualizar';

  @override
  String main_CompatibilityIssueDialog_contentCoreVersionUnsupportedExceptionError(
    String actual,
    String supportedConstraint,
  ) {
    return 'Versão do Cloud Backend incompatível, entre em contato com o administrador do seu sistema.\n\nVersão da instância:\n$actual\n\nVersão suportada:\n$supportedConstraint';
  }

  @override
  String get main_CompatibilityIssueDialog_title => 'Problema de compatibilidade';

  @override
  String get main_AppUpdateRequiredDialog_title => 'Atualização necessária';

  @override
  String get main_AppUpdateRequiredDialog_description =>
      'A versão do seu app não é mais suportada. Atualize o aplicativo para continuar.';

  @override
  String get main_AppUpdateRequiredDialog_currentVersionLabel => 'Versão do app';

  @override
  String get main_AppUpdateRequiredDialog_buildVersionLabel => 'Versão do build';

  @override
  String main_AppUpdateRequiredDialog_currentVersionValue(String storeVersion, String appVersion) {
    return '$appVersion (build $storeVersion)';
  }

  @override
  String get main_AppUpdateRequiredDialog_minimumVersionLabel => 'Versão mínima exigida';

  @override
  String get messaging_ActionBtn_retry => 'Tentar novamente';

  @override
  String get messaging_ChooseContact_cancel => 'Cancelar';

  @override
  String get messaging_ChooseContact_empty => 'Nenhum contato encontrado';

  @override
  String get messaging_ChooseContact_title => 'Escolha o contato:';

  @override
  String get messaging_ConversationBuilders_back => 'Voltar';

  @override
  String get messaging_ConversationBuilders_cancel => 'Cancelar';

  @override
  String messaging_ConversationBuilders_contactExtension(String extension) {
    return 'Ramal: $extension';
  }

  @override
  String get messaging_ConversationBuilders_contactOrNumberSearch_hint => 'Informe o nome ou o número de telefone';

  @override
  String get messaging_ConversationBuilders_contactSearch_hint => 'Pesquisar contatos';

  @override
  String get messaging_ConversationBuilders_create => 'Criar';

  @override
  String get messaging_ConversationBuilders_createGroup => 'Criar grupo';

  @override
  String get messaging_ConversationBuilders_externalContacts_heading => 'Contatos do PABX em nuvem';

  @override
  String get messaging_ConversationBuilders_invalidNumber_message1 =>
      'O contato tem um número de telefone inválido. Ele deve estar no formato ';

  @override
  String get messaging_ConversationBuilders_invalidNumber_message2 => '. Corrija-o na sua agenda de contatos.';

  @override
  String get messaging_ConversationBuilders_invalidNumber_ok => 'Fechar';

  @override
  String get messaging_ConversationBuilders_invalidNumber_title => 'Número de telefone inválido';

  @override
  String get messaging_ConversationBuilders_invite_heading => 'Convidar usuários:';

  @override
  String get messaging_ConversationBuilders_localContacts_heading => 'Contatos locais';

  @override
  String get messaging_ConversationBuilders_membersHeadline => 'Membros';

  @override
  String get messaging_ConversationBuilders_nameFieldEmpty => 'Informe um nome para o grupo';

  @override
  String get messaging_ConversationBuilders_nameFieldLabel => 'Nome do grupo';

  @override
  String get messaging_ConversationBuilders_nameFieldShort => 'O nome do grupo deve ter pelo menos 3 caracteres';

  @override
  String get messaging_ConversationBuilders_next_action => 'Avançar';

  @override
  String get messaging_ConversationBuilders_noContacts => 'Nenhum contato corresponde à pesquisa';

  @override
  String get messaging_ConversationBuilders_numberFormatExample =>
      '+ [código do país] [código de área/operadora] [número do assinante]';

  @override
  String get messaging_ConversationBuilders_numberSearch_errorError =>
      'O número de telefone informado é inválido. Ele deve ser informado no formato: ';

  @override
  String get messaging_ConversationBuilders_numberSearch_errorHint => 'Formato do número de telefone: ';

  @override
  String get messaging_ConversationBuilders_title_group => 'Criar grupo';

  @override
  String get messaging_ConversationBuilders_title_new => 'Nova conversa';

  @override
  String get messaging_Conversation_failure => 'Erro ao carregar a conversa';

  @override
  String get messaging_ConversationScreen_titleAvailable => 'disponível';

  @override
  String get messaging_ConversationScreen_titlePrefix => 'Diálogo:';

  @override
  String get messaging_ConversationsScreen_chatsSearch_hint => 'Informe o nome da conversa ou do usuário';

  @override
  String get messaging_ConversationsScreen_empty => 'Nenhuma conversa iniciada ainda';

  @override
  String get messaging_ConversationsScreen_messages_title => 'Mensagens';

  @override
  String get messaging_ConversationsScreen_noNumberAlert_text =>
      'Você precisa ter um número de telefone vinculado à sua conta para enviar mensagens SMS';

  @override
  String get messaging_ConversationsScreen_noNumberAlert_title => 'Sem número de telefone';

  @override
  String get messaging_ConversationsScreen_selectNumberSheet_title => 'Selecione um número';

  @override
  String get messaging_ConversationsScreen_smses_title => 'SMS';

  @override
  String get messaging_ConversationsScreen_smssSearch_hint => 'Informe o número de telefone';

  @override
  String get messaging_ConversationsScreen_unsupported =>
      'O sistema remoto não oferece suporte a mensagens, entre em contato com o administrador para ativá-las';

  @override
  String get messaging_Conversations_tile_empty => 'Nenhuma mensagem ainda';

  @override
  String get messaging_Conversations_tile_you => 'Você';

  @override
  String get messaging_DeleteConversationDialog_content => 'Ela será removida deste dispositivo e da conta.';

  @override
  String get messaging_DeleteConversationDialog_title => 'Excluir esta conversa?';

  @override
  String get messaging_DialogInfo_deleteAsk => 'Tem certeza de que deseja excluir este diálogo?';

  @override
  String get messaging_DialogInfo_deleteBtn => 'Excluir diálogo';

  @override
  String get messaging_DialogInfo_title => 'Dados do contato';

  @override
  String get messaging_GroupAuthorities_moderator => 'moderador';

  @override
  String get messaging_GroupAuthorities_noauthorities => 'membro';

  @override
  String get messaging_GroupAuthorities_owner => 'proprietário';

  @override
  String get messaging_GroupInfo_addUserBtnText => 'Adicionar usuário';

  @override
  String get messaging_GroupInfo_deleteLeaveBtnText => 'Excluir e sair';

  @override
  String get messaging_GroupInfo_groupMembersHeadline => 'Membros do grupo';

  @override
  String get messaging_LeaveGroupDialog_content =>
      'Você deixará de receber as mensagens dele. A conversa continua para todos os outros.';

  @override
  String get messaging_LeaveGroupDialog_title => 'Sair deste grupo?';

  @override
  String get messaging_GroupInfo_leaveAndDeleteAsk => 'Tem certeza de que deseja sair deste grupo e excluí-lo?';

  @override
  String get messaging_GroupInfo_leaveAsk => 'Tem certeza de que deseja sair deste grupo?';

  @override
  String get messaging_GroupInfo_leaveBtnText => 'Sair do grupo';

  @override
  String get messaging_GroupInfo_makeModeratorAsk => 'Tem certeza de que deseja tornar este usuário moderador?';

  @override
  String get messaging_GroupInfo_makeModeratorBtnText => 'Tornar moderador';

  @override
  String get messaging_GroupInfo_removeModeratorAsk =>
      'Tem certeza de que deseja remover este usuário dos moderadores?';

  @override
  String get messaging_GroupInfo_removeUserAsk => 'Tem certeza de que deseja remover este usuário do grupo?';

  @override
  String get messaging_GroupInfo_removeUserBtnText => 'Remover';

  @override
  String get messaging_GroupInfo_title => 'Dados do grupo';

  @override
  String messaging_GroupInfo_titlePrefix(int id) {
    return 'Grupo $id';
  }

  @override
  String get messaging_GroupInfo_unmakeModeratorBtnText => 'Remover de moderador';

  @override
  String get messaging_MessageField_hint => 'Digite uma mensagem';

  @override
  String get messaging_MessageListView_typingTrail => 'está digitando...';

  @override
  String get messaging_MessageView_actionsHint => 'abrir as ações da mensagem';

  @override
  String get messaging_MessageView_delete => 'Excluir';

  @override
  String get messaging_MessageView_deleted => '[excluída]';

  @override
  String get messaging_MessageView_edit => 'Editar';

  @override
  String get messaging_MessageView_edited => '[editada]';

  @override
  String get messaging_MessageView_forward => 'Encaminhar';

  @override
  String get messaging_MessageView_reply => 'Responder';

  @override
  String get messaging_MessageView_textcopy => 'Copiar para a área de transferência';

  @override
  String get messaging_MessageView_today => 'Hoje';

  @override
  String get messaging_MessageView_yesterday => 'Ontem';

  @override
  String get messaging_NotificationMute_title => 'Notificações';

  @override
  String get messaging_NotificationMute_on => 'Ativadas';

  @override
  String get messaging_NotificationMute_muted => 'Silenciadas';

  @override
  String messaging_NotificationMute_mutedUntil(String time) {
    return 'Silenciadas até $time';
  }

  @override
  String get messaging_NotificationMute_sheetTitle => 'Silenciar notificações';

  @override
  String get messaging_NotificationMute_forOneHour => 'Por 1 hora';

  @override
  String get messaging_NotificationMute_forEightHours => 'Por 8 horas';

  @override
  String get messaging_NotificationMute_forTwoDays => 'Por 2 dias';

  @override
  String get messaging_NotificationMute_forever => 'Para sempre';

  @override
  String get messaging_NotificationMute_unmute => 'Reativar som';

  @override
  String get messaging_ParticipantName_unknown => 'Usuário desconhecido';

  @override
  String get messaging_ParticipantName_you => 'Você';

  @override
  String get messaging_SmsSendingStatus_delivered => 'entregue';

  @override
  String get messaging_SmsSendingStatus_failed => 'falhou';

  @override
  String get messaging_SmsSendingStatus_sent => 'enviada';

  @override
  String get messaging_SmsSendingStatus_waiting => 'aguardando';

  @override
  String get messaging_StateBar_connecting => 'CONECTANDO';

  @override
  String get messaging_Watch_search => 'Pesquisar conversas';

  @override
  String get messaging_Watch_searchSms => 'Pesquisar SMS';

  @override
  String get messaging_Watch_list => 'Lista';

  @override
  String get messaging_Watch_statusInitializing => 'Iniciando conversas';

  @override
  String get messaging_Watch_statusConnecting => 'Conectando às conversas';

  @override
  String get messaging_Watch_statusDisconnected => 'As conversas estão offline';

  @override
  String messaging_Watch_nextMembers(int count) {
    return 'Avançar ($count)';
  }

  @override
  String get messaging_Watch_notFound => 'Nenhuma conversa encontrada';

  @override
  String get messaging_Watch_newChat => 'Nova conversa';

  @override
  String get messaging_Watch_newSms => 'Novo SMS';

  @override
  String get messaging_Watch_mine => 'Você';

  @override
  String get messaging_Watch_markDelivered => 'Entregue';

  @override
  String get messaging_Watch_markPending => 'Enviando';

  @override
  String get messaging_Watch_markSent => 'Enviada';

  @override
  String get messaging_Watch_markRead => 'Lida';

  @override
  String get messaging_StateBar_error => 'DESCONECTADO';

  @override
  String get messaging_StateBar_initializing => 'INICIALIZANDO';

  @override
  String get notifications_errorSnackBarAction_callSdpConfiguration => 'Configuração de SDP inválida';

  @override
  String get notifications_errorSnackBarAction_callUserMedia => 'Verificar';

  @override
  String get notifications_messageSnackBar_callVideoDowngraded =>
      'Atendida com a câmera desligada - permissão da câmera não concedida';

  @override
  String get notifications_messageSnackBarAction_callVideoDowngraded => 'Configurações';

  @override
  String get notifications_messageSnackBar_screenShareFailed => 'Não foi possível iniciar o compartilhamento de tela';

  @override
  String get notifications_messageSnackBar_screenShareVideoRefused =>
      'O outro lado não aceita vídeo - compartilhamento de tela encerrado';

  @override
  String get notifications_messageSnackBar_conferenceFailed => 'Não foi possível criar a conferência';

  @override
  String get notifications_messageSnackBar_conferenceVideoLeg =>
      'Uma chamada de vídeo não pode entrar em uma conferência';

  @override
  String get notifications_messageSnackBar_conferenceEnded => 'A conferência terminou, as chamadas continuam';

  @override
  String get notifications_errorSnackBar_activeLineBlindTransferWarning =>
      'Você já está na linha com o destinatário para o qual está tentando fazer a transferência direta';

  @override
  String get notifications_errorSnackBar_blindTransferFailed => 'A transferência falhou, voltando para a chamada ativa';

  @override
  String get notifications_errorSnackBar_attendedTransferDeclined => 'A pessoa recusou, voltando para a chamada';

  @override
  String get notifications_errorSnackBar_attendedTransferUnanswered => 'Sem resposta, voltando para a chamada';

  @override
  String get notifications_errorSnackBar_appOffline => 'Seu aplicativo está offline no momento';

  @override
  String get notifications_errorSnackBar_appOnline => 'Seu aplicativo está online';

  @override
  String get notifications_errorSnackBar_appUnregistered =>
      'Seu aplicativo está desconectado dos servidores centrais no momento e, por isso, não pode fazer chamadas agora. Vá até a página de configurações e desative e ative novamente a chave de status online para restabelecer a conexão';

  @override
  String get notifications_errorSnackBar_callConnect => 'Falha ao conectar ao servidor central, tentando reconectar';

  @override
  String get notifications_errorSnackBar_callNegotiationTimeout =>
      'Não foi possível estabelecer a chamada, tente novamente mais tarde';

  @override
  String get notifications_errorSnackBar_generalUnableToCall =>
      'Não foi possível estabelecer a chamada, tente novamente mais tarde';

  @override
  String get notifications_errorSnackBar_callServiceBusyLine =>
      'Não é possível fazer a chamada agora porque a linha está ocupada. Tente novamente mais tarde.';

  @override
  String get notifications_errorSnackBar_callSignalingClientNotConnect =>
      'Não foi possível iniciar a chamada, verifique o status da conexão';

  @override
  String get notifications_errorSnackBar_callSignalingClientSessionMissed => 'Erro de autenticação, entre novamente';

  @override
  String get notifications_errorSnackBar_callUndefinedLine => 'Não há linhas livres para iniciar a chamada';

  @override
  String get notifications_errorSnackBar_callMediaTrackSetup => 'Falha ao configurar a chamada, tente novamente';

  @override
  String get notifications_errorSnackBar_callUserMedia =>
      'A chamada não pode usar o microfone ou a câmera. Verifique as permissões do app';

  @override
  String get notifications_errorSnackBar_callWhileOffline =>
      'Não foi possível iniciar a chamada, verifique o status da conexão';

  @override
  String get notifications_errorSnackBar_callWhileUnregistered =>
      'No momento, você não pode fazer chamadas. Verifique o status da sua conta ou entre em contato com o suporte.';

  @override
  String get notifications_errorSnackBar_sessionExpired => 'Sua sessão expirou. Entre novamente.';

  @override
  String get notifications_errorSnackBar_accountNotFound =>
      'Sua conta não foi encontrada. Ela pode ter sido desativada ou removida. Entre em contato com o administrador.';

  @override
  String get notifications_errorSnackBar_SignalingConnectFailed =>
      'Falha ao conectar ao servidor central, tentando reconectar';

  @override
  String notifications_errorSnackBar_signalingDisconnectWithCodeName(String codeName) {
    return 'Desconectado do servidor central com o código: $codeName';
  }

  @override
  String notifications_errorSnackBar_signalingDisconnectWithSystemReason(String reason) {
    return 'Desconectado do servidor central pelo seguinte motivo: $reason';
  }

  @override
  String notifications_errorSnackBar_emergencyNumber(String number) {
    return '$number é um número de emergência e não pode ser discado pelo app';
  }

  @override
  String get notifications_errorSnackBarAction_emergencyNumber => 'Abrir discador';

  @override
  String get notifications_errorSnackBar_SignalingSessionMissed => 'Erro de autenticação, entre novamente';

  @override
  String get notifications_errorSnackBar_sipRegistrationFailed_Unavailable =>
      'Falha no registro no sistema VoIP remoto, o serviço está indisponível';

  @override
  String get notifications_errorSnackBar_sipRegistrationFailed_Unexpected =>
      'Falha no registro no sistema VoIP remoto devido a um erro inesperado';

  @override
  String notifications_errorSnackBar_sipRegistrationFailed_WithSystemReason(String reason) {
    return 'Falha no registro no sistema VoIP remoto pelo seguinte motivo: $reason';
  }

  @override
  String get notifications_errorSnackBar_sipServiceUnavailable => 'Erro de autenticação no sistema VoIP remoto';

  @override
  String get notifications_messageSnackBar_appOffline => 'Seu aplicativo está offline no momento';

  @override
  String get notifications_successSnackBar_appOnline => 'Seu aplicativo está online';

  @override
  String get notifications_missedCall_title => 'Chamada perdida';

  @override
  String get notifications_missedCall_unknownCaller => 'Desconhecido';

  @override
  String get numberActions_audioCall => 'Chamada de áudio';

  @override
  String numberActions_callFrom(String number) {
    return 'Ligar de $number';
  }

  @override
  String get numberActions_callLog => 'Ver histórico de chamadas';

  @override
  String get numberActions_chat => 'Enviar mensagem na conversa';

  @override
  String get numberActions_copyCallId => 'Copiar ID da chamada';

  @override
  String get numberActions_copyNumber => 'Copiar número';

  @override
  String get numberActions_delete => 'Excluir';

  @override
  String get numberActions_sendSms => 'Enviar mensagem SMS';

  @override
  String get numberActions_transfer => 'Transferir a chamada atual';

  @override
  String get numberActions_videoCall => 'Chamada de vídeo';

  @override
  String get numberActions_viewContact => 'Ver contato';

  @override
  String get permission_Button_notNow => 'Agora não';

  @override
  String get permission_Button_request => 'Continuar';

  @override
  String get permission_fullScreenNotification_Text_optional =>
      'Você pode continuar sem isso. As chamadas recebidas chegarão como notificação em vez de abrir em tela cheia e, se o telefone estiver bloqueado com PIN, padrão ou impressão digital, será preciso desbloqueá-lo para atender pela tela de bloqueio.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step1 => 'Abra as Configurações do telefone.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step2 =>
      'Acesse \'Acesso especial de apps\' na seção \'Apps e notificações\'.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step3 =>
      'Encontre e toque em \'Gerenciar intents de tela cheia\'.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step4 =>
      'Selecione o app cujas notificações em tela cheia você quer gerenciar.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step5 =>
      'Ative ou desative a permissão de notificações em tela cheia para esse app.';

  @override
  String get permission_manageFullScreenNotificationPermissions => 'Gerenciar permissões de notificação em tela cheia';

  @override
  String get permission_manufacturer_Button_gotIt => 'Entendi';

  @override
  String get permission_manufacturer_Button_toSettings => 'Abrir Configurações do app';

  @override
  String get permission_manufacturer_Text_heading =>
      'Para garantir a melhor experiência de uso, as seguintes permissões precisam ser concedidas ao app manualmente:';

  @override
  String get permission_manufacturer_Text_trailing => 'As permissões podem ser alteradas a qualquer momento.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip1 =>
      'Abra a tela \"Outras permissões\" deste app usando o botão abaixo.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip2 =>
      'Ative \"Exibir janelas pop-up durante a execução em segundo plano\" para que as chamadas recebidas apareçam enquanto o app está em segundo plano.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip3 =>
      'Ative \"Mostrar na tela de bloqueio\" para que as chamadas recebidas apareçam sobre a tela de bloqueio.';

  @override
  String get permission_Text_description =>
      'Para garantir a melhor experiência de uso, o app precisa das seguintes permissões: microfone para chamadas de áudio, câmera para chamadas de vídeo e contatos para facilitar o acesso a eles pelo app.\n\nAs permissões podem ser alteradas a qualquer momento.';

  @override
  String get permission_Text_title => 'Permissões';

  @override
  String get persistentConnectionReminderContent =>
      'Você precisa abrir o app manualmente pelo menos uma vez depois que o telefone for reiniciado para restabelecer a conexão persistente e receber chamadas.';

  @override
  String get persistentConnectionReminderTitle => 'Lembrete importante';

  @override
  String get batteryOptimizationWarningTitle => 'Otimização de bateria ativa';

  @override
  String get batteryOptimizationWarningContent =>
      'A otimização de bateria está ativa neste dispositivo. Isso pode causar chamadas perdidas quando a tela se apaga. Desative-a para manter a conexão persistente ativa.';

  @override
  String get batteryOptimizationWarningOpenSettings => 'Abrir Configurações';

  @override
  String get presence_activity_appointment_name => 'Em um compromisso';

  @override
  String get presence_activity_away_name => 'Ausente';

  @override
  String get presence_activity_busy_name => 'Ocupado';

  @override
  String get presence_activity_doNotDisturb_name => 'Não perturbe';

  @override
  String get presence_activity_inTransit_name => 'Em trânsito';

  @override
  String get presence_activity_meal_name => 'Em refeição';

  @override
  String get presence_activity_meeting_name => 'Em reunião';

  @override
  String get presence_activity_none_name => 'Nenhuma';

  @override
  String get presence_activity_onThePhone_name => 'Ao telefone';

  @override
  String get presence_activity_permanentAbsence_name => 'Ausência permanente';

  @override
  String get presence_activity_sleeping_name => 'Dormindo';

  @override
  String get presence_activity_travel_name => 'Viajando';

  @override
  String get presence_activity_vacation_name => 'De férias';

  @override
  String get presence_badge_state_available => 'Disponível';

  @override
  String get presence_badge_state_onCall => 'Em chamada';

  @override
  String get presence_badge_state_registered => 'Registrado';

  @override
  String get presence_badge_state_unavailable => 'Indisponível';

  @override
  String get presence_badge_state_unregistered => 'Não registrado';

  @override
  String get presence_infoView_activity => 'Atividade:';

  @override
  String get presence_infoView_available => 'Disponível:';

  @override
  String get presence_infoView_available_false => 'Inacessível';

  @override
  String get presence_infoView_available_true => 'Disponível';

  @override
  String get presence_infoView_client => 'Cliente:';

  @override
  String get presence_infoView_device => 'Dispositivo:';

  @override
  String get presence_infoView_localTime => 'Hora local:';

  @override
  String get presence_infoView_note => 'Nota:';

  @override
  String get presence_infoView_statusIcon => 'Ícone de status:';

  @override
  String get presence_infoView_timeZone => 'Fuso horário:';

  @override
  String get presence_infoView_title => 'Informações de presença:';

  @override
  String get presence_infoView_updated => 'Atualizado:';

  @override
  String presence_infoView_source(Object source) {
    return 'Origem: $source';
  }

  @override
  String get presence_infoView_source_direct => 'de aplicativo para aplicativo (direto)';

  @override
  String get presence_infoView_source_registration => 'registro no PBX';

  @override
  String get presence_infoView_source_sip => 'presença SIP';

  @override
  String get presence_infoView_source_sipAndDirect => 'presença SIP e de aplicativo para aplicativo';

  @override
  String get presence_infoView_legendButton => 'O que significam as marcas de status';

  @override
  String get presence_legendDialog_title => 'Como ler o status';

  @override
  String get presence_legendDialog_sourcesTitle => 'De onde vem o status';

  @override
  String get presence_legendDialog_sourceDirect =>
      'De aplicativo para aplicativo (direto): o que o contato definiu neste aplicativo ou na versão web.';

  @override
  String get presence_legendDialog_sourceSip =>
      'Presença SIP: o que um telefone de mesa ou outro aplicativo SIP publica. Mostrada para os contatos em que você está inscrito.';

  @override
  String get presence_legendDialog_sourceRegistration =>
      'Registro no PBX: se o telefone do contato está conectado. Usado quando nenhum status foi publicado.';

  @override
  String get presence_legendDialog_sourcesNote =>
      'É mostrada a primeira fonte que sabe algo. Com vários dispositivos, vale o status definido por último.';

  @override
  String get presence_legendDialog_marksTitle => 'O que significam as marcas';

  @override
  String get presence_legendDialog_markAvailable => 'Status publicado: disponível';

  @override
  String get presence_legendDialog_markUnavailable => 'Status publicado: indisponível';

  @override
  String get presence_legendDialog_markActivity => 'Status publicado com uma atividade, como ausente';

  @override
  String get presence_legendDialog_markDoNotDisturb => 'Não perturbe ou ocupado';

  @override
  String get presence_legendDialog_markOnCall => 'Em chamada';

  @override
  String get presence_legendDialog_markRegistered => 'Nenhum status publicado, o telefone está registrado';

  @override
  String get presence_legendDialog_markUnregistered => 'Nenhum status publicado, o telefone não está registrado';

  @override
  String get presence_preset_absent_name => 'Ausente';

  @override
  String get presence_preset_absent_note => 'Ausente';

  @override
  String get presence_preset_appointment_name => 'Compromisso';

  @override
  String get presence_preset_appointment_note => 'Em um compromisso';

  @override
  String get presence_preset_available_name => 'Disponível';

  @override
  String get presence_preset_away_name => 'Ausente';

  @override
  String get presence_preset_away_note => 'Ausente';

  @override
  String get presence_preset_dnd_name => 'Não perturbe';

  @override
  String get presence_preset_dnd_note => 'Não perturbe';

  @override
  String get presence_preset_inTransit_name => 'Trânsito';

  @override
  String get presence_preset_inTransit_note => 'Em trânsito';

  @override
  String get presence_preset_meal_name => 'Refeição';

  @override
  String get presence_preset_meal_note => 'Em refeição';

  @override
  String get presence_preset_meeting_name => 'Reunião';

  @override
  String get presence_preset_meeting_note => 'Em reunião';

  @override
  String get presence_preset_sleeping_name => 'Dormindo';

  @override
  String get presence_preset_sleeping_note => 'Dormindo';

  @override
  String get presence_preset_travel_name => 'Viajando';

  @override
  String get presence_preset_travel_note => 'Viajando';

  @override
  String get presence_preset_unavailable_name => 'Indisponível';

  @override
  String get presence_preset_vacation_name => 'Férias';

  @override
  String get presence_preset_vacation_note => 'De férias';

  @override
  String get presence_settings_activity_label => 'Atividade';

  @override
  String get presence_settings_activity_tooltip =>
      'Descreve a atividade atual com mais detalhes. Usa o elemento \"activities\" da extensão SIP \"RPID\" no conteúdo pidf (consulte a RFC 4480)';

  @override
  String get presence_settings_availability_title => 'Disponibilidade:';

  @override
  String get presence_settings_availability_tooltip =>
      'Representa a disponibilidade geral para comunicações no serviço SIP. Usa o elemento SIP \"Status\" no conteúdo pidf com os valores \"open/closed\" (consulte a RFC 3863)';

  @override
  String get presence_Watch_configOnPhone => 'Disponibilidade, nota, atividade e ícone de status: no telefone';

  @override
  String get presence_settings_config_title => 'Configuração:';

  @override
  String get presence_settings_dnd_title => 'Rejeitar chamadas (DND)';

  @override
  String get presence_settings_dnd_tooltip =>
      'Quando ativado, todas as chamadas recebidas serão rejeitadas automaticamente pelo servidor com a resposta \"603 Declined\".';

  @override
  String get presence_settings_note_label => 'Nota';

  @override
  String get presence_settings_note_tooltip =>
      'Uma nota de texto curta que descreve o status atual em detalhes. Usa o elemento SIP \"note\" no conteúdo pidf (consulte a RFC 3863)';

  @override
  String get presence_settings_presets_label => 'Escolher predefinição';

  @override
  String get presence_settings_presets_label_custom => 'Personalizado';

  @override
  String get presence_settings_presets_title => 'Predefinições:';

  @override
  String get presence_settings_statusIcon_none => 'Nenhum';

  @override
  String get presence_settings_statusIcon_title => 'Ícone de status:';

  @override
  String get recents_ActionsButton_label => 'Mais ações';

  @override
  String recents_BodyCenter_empty(Object filter) {
    return 'No momento, você não tem chamadas ${filter}recentes.';
  }

  @override
  String get recents_ClearHistoryAction_label => 'Limpar histórico de chamadas';

  @override
  String get recents_ClearHistoryDialog_contentAccount =>
      'Todas as chamadas serão removidas de Recentes em todos os dispositivos conectados a esta conta. Novas chamadas aparecerão normalmente.';

  @override
  String get recents_ClearHistoryDialog_contentDevice =>
      'Todas as chamadas serão removidas de Recentes neste dispositivo. Novas chamadas aparecerão normalmente.';

  @override
  String get recents_ClearHistoryDialog_title => 'Limpar histórico de chamadas?';

  @override
  String get recents_DeleteConfirmDialog_content => 'Tem certeza de que deseja excluir este registro de chamada?';

  @override
  String get recents_DeleteConfirmDialog_title => 'Confirmar exclusão';

  @override
  String get recents_FilterPicker_label => 'Mostrar chamadas';

  @override
  String get recents_HistoryTile_missedCallText => 'Perdida';

  @override
  String recents_snackBar_deleted(String name) {
    return '$name excluído';
  }

  @override
  String get recents_snackBar_historyClearFailed =>
      'Não foi possível limpar o histórico de chamadas. Verifique a conexão e tente novamente.';

  @override
  String get recents_snackBar_historyClearUnsupported =>
      'Este servidor não oferece suporte à limpeza do histórico de chamadas.';

  @override
  String get recents_snackBar_historyCleared => 'Histórico de chamadas limpo';

  @override
  String get recentsVisibilityFilter_all => 'Todas';

  @override
  String get recentsVisibilityFilter_all_preposit => 'todas';

  @override
  String get recentsVisibilityFilter_incoming => 'Recebidas';

  @override
  String get recentsVisibilityFilter_incoming_preposit => 'recebidas';

  @override
  String get recentsVisibilityFilter_missed => 'Perdidas';

  @override
  String get recentsVisibilityFilter_missed_preposit => 'perdidas';

  @override
  String get recentsVisibilityFilter_outgoing => 'Efetuadas';

  @override
  String get recentsVisibilityFilter_outgoing_preposit => 'efetuadas';

  @override
  String recentTimeAfterMidnight(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.yMd(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String recentTimeBeforeMidnight(DateTime time) {
    final intl.DateFormat timeDateFormat = intl.DateFormat.Hm(localeName);
    final String timeString = timeDateFormat.format(time);

    return '$timeString';
  }

  @override
  String get request_Id => 'ID da solicitação';

  @override
  String get request_StatusCode => 'Código de status';

  @override
  String get request_StatusName => 'Nome do status';

  @override
  String get sessionStatus_AppBar_waitingForNetwork => 'Aguardando a rede...';

  @override
  String get sessionStatus_AppBar_waitingForConnection => 'Aguardando a conexão...';

  @override
  String get sessionStatus_AppBar_disconnected => 'Desconectado';

  @override
  String get sessionStatus_AppBar_connecting => 'Conectando...';

  @override
  String get sessionStatus_AppBar_serviceUnavailable => 'Serviço temporariamente indisponível';

  @override
  String get sessionStatus_pushNotificationServiceProblem => 'Problema na configuração do serviço de notificações push';

  @override
  String get sessionStatus_subtitle_connectivityNone => 'Verifique o Wi-Fi ou os dados móveis';

  @override
  String get sessionStatus_subtitle_diagnostic => 'Toque para ver o diagnóstico';

  @override
  String get sessionStatus_subtitle_inProgress => 'Conectando ao servidor...';

  @override
  String get sessionStatus_subtitle_ready => 'As chamadas chegam a esta conta';

  @override
  String get sessionStatus_subtitle_registrationOff => 'O registro está desativado';

  @override
  String get sessionStatus_subtitle_serviceUnavailable => 'Sua conexão está normal, toque para ver os detalhes';

  @override
  String get session_Teardown_progressText => 'Saindo...';

  @override
  String get session_Restart_progressText => 'Aplicando alterações do servidor...';

  @override
  String get session_Restart_loadingText => 'Carregando suas configurações do servidor...';

  @override
  String get session_Restart_unreachableText =>
      'Não foi possível acessar o servidor para carregar suas configurações. Verifique sua conexão e tente novamente.';

  @override
  String get session_Restart_retryButton => 'Tentar novamente';

  @override
  String get session_Restart_logoutButton => 'Sair';

  @override
  String get sessions_AppBar_title => 'Sessões ativas';

  @override
  String get sessions_AppType_android => 'App Android';

  @override
  String get sessions_AppType_ios => 'App iOS';

  @override
  String get sessions_AppType_linux => 'App Linux';

  @override
  String get sessions_AppType_macos => 'App macOS';

  @override
  String get sessions_AppType_smart => 'Dispositivo inteligente';

  @override
  String get sessions_AppType_unknown => 'Dispositivo desconhecido';

  @override
  String get sessions_AppType_web => 'App web';

  @override
  String get sessions_AppType_windows => 'App Windows';

  @override
  String get sessions_AutoTerminate_title => 'Encerrar sessões inativas';

  @override
  String get sessions_AutoTerminate_never => 'Nunca';

  @override
  String get sessions_AutoTerminate_oneWeek => '1 semana';

  @override
  String get sessions_AutoTerminate_oneMonth => '1 mês';

  @override
  String get sessions_AutoTerminate_threeMonths => '3 meses';

  @override
  String sessions_AutoTerminate_days(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days dias', one: '$days dia');
    return '$_temp0';
  }

  @override
  String sessions_AutoTerminate_default(String period) {
    return 'Padrão ($period)';
  }

  @override
  String get sessions_AutoTerminate_other => 'Outro…';

  @override
  String sessions_AutoTerminate_adminLimitNote(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days dias', one: '$days dia');
    return 'Sessões inativas há mais de $_temp0 são encerradas automaticamente. Esse limite é definido pelo administrador.';
  }

  @override
  String sessions_AutoTerminate_info(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days dias', one: '$days dia');
    return 'Sessões inativas são encerradas após $_temp0';
  }

  @override
  String get sessions_AutoTerminateOther_title => 'Período personalizado';

  @override
  String get sessions_AutoTerminateOther_label => 'Dias';

  @override
  String sessions_AutoTerminateOther_range(int max) {
    return 'De 1 a $max';
  }

  @override
  String get sessions_AutoTerminateOther_save => 'Salvar';

  @override
  String get sessions_Button_retry => 'Tentar novamente';

  @override
  String get sessions_Watch_revokeAllOthers => 'Sair das outras';

  @override
  String get sessions_Button_revokeAllOthers => 'Sair das outras sessões';

  @override
  String get sessions_Placeholder_empty => 'Nenhuma sessão ativa';

  @override
  String get sessions_Placeholder_failure => 'Não foi possível carregar as sessões ativas';

  @override
  String get sessions_RevokeAllConfirmDialog_content =>
      'Os outros dispositivos conectados a esta conta serão desconectados.';

  @override
  String get sessions_RevokeAllConfirmDialog_title => 'Sair das outras sessões?';

  @override
  String get sessions_RevokeConfirmDialog_content => 'Este dispositivo será desconectado da conta.';

  @override
  String get sessions_RevokeConfirmDialog_title => 'Sair desta sessão?';

  @override
  String get sessions_SnackBar_autoTerminateFailed =>
      'Não foi possível alterar quando as sessões inativas são encerradas';

  @override
  String get sessions_SnackBar_autoTerminateLimitChanged =>
      'O administrador alterou o limite. Escolha o período novamente.';

  @override
  String get sessions_SnackBar_autoTerminateNotSupported =>
      'A escolha de quando as sessões inativas são encerradas não está mais disponível';

  @override
  String sessions_Section_otherDevices(int count) {
    return 'Outros dispositivos · $count';
  }

  @override
  String get sessions_SnackBar_revokeFailed => 'Não foi possível encerrar a sessão';

  @override
  String get sessions_Tile_activeNow => 'Ativa agora';

  @override
  String sessions_Tile_appVersion(String version) {
    return 'App $version';
  }

  @override
  String get sessions_Tile_currentSession => 'Este dispositivo';

  @override
  String get sessions_Tile_revokeTooltip => 'Sair';

  @override
  String get settings_AboutText_ApplicationEmbeddedLinks => 'Links incorporados ao aplicativo';

  @override
  String get settings_AboutText_BackendCapabilities => 'Recursos do backend';

  @override
  String get settings_AboutBackendCapabilities_none => 'O backend não informa nenhum recurso.';

  @override
  String get settings_AboutBackendCapabilities_removedOnServer =>
      'Desativado no servidor - continua em uso até o app ser iniciado novamente';

  @override
  String get settings_AboutBackendCapabilities_addedOnServer =>
      'Ativado no servidor - só entra em uso quando o app for iniciado novamente';

  @override
  String get settings_AboutText_ThirdPartyLicenses => 'Licenças de terceiros';

  @override
  String get settings_AboutText_AppSessionIdentifier => 'Identificador da sessão do aplicativo';

  @override
  String get settings_AboutText_AppVersion => 'Versão do app';

  @override
  String get settings_AboutText_BundleVersion => 'Versão do bundle';

  @override
  String get settings_AboutText_CoreVersion => 'Versão do core';

  @override
  String get settings_AboutText_CoreVersionUndefined => '?.?.?';

  @override
  String get settings_AboutText_FCMPushNotificationToken => 'Token de notificação push do FCM';

  @override
  String get settings_AboutText_StoreVersion => 'Versão do build na loja';

  @override
  String get settings_AccountDeleteConfirmDialog_content => 'Tem certeza de que deseja excluir a conta?';

  @override
  String get settings_AccountDeleteConfirmDialog_title => 'Confirmar exclusão da conta';

  @override
  String get settings_AccountDeleteNotSupported_message =>
      'Infelizmente, seu produto não oferece suporte à exclusão de conta.';

  @override
  String get settings_AppBarTitle_myAccount => 'Minha conta';

  @override
  String get settings_SemanticsLabel_editAccount => 'Editar dados da conta';

  @override
  String get settings_audioProcessing_Section_AGC_title => 'Controle automático de ganho';

  @override
  String get settings_audioProcessing_Section_AM_title => 'Espelhamento de áudio';

  @override
  String get settings_audioProcessing_Section_EC_title => 'Cancelamento de eco';

  @override
  String get settings_audioProcessing_Section_HPF_title => 'Filtro passa-alta';

  @override
  String get settings_audioProcessing_Section_NS_title => 'Supressão de ruído do sistema';

  @override
  String get settings_audioProcessing_Section_title => 'Pré-processamento de áudio';

  @override
  String get settings_audioProcessing_Section_tooltip =>
      'Pode ser usado para ajustar a qualidade do áudio a necessidades ou ambientes específicos, como gravação em estúdio ou microfone externo. \n\nIgnorar processamento de voz - instrui o sistema a não aplicar o processamento de voz por hardware (requer reiniciar o app).';

  @override
  String get settings_audioProcessing_Section_VNR_title => 'Redução de ruído adicional (RNNoise)';

  @override
  String get settings_audioProcessing_Section_VP_title => 'Ignorar processamento de voz';

  @override
  String get settings_call_codecs_preferred_audio_default => 'Automático';

  @override
  String get settings_call_codecs_preferred_audio_tip =>
      'O codec de áudio preferencial é usado nas chamadas de áudio. Se o codec não for suportado pelo dispositivo, a chamada será estabelecida com o próximo codec disponível.';

  @override
  String get settings_call_codecs_preferred_audio_title => 'Codec de áudio preferencial';

  @override
  String get settings_call_codecs_preferred_video_default => 'Automático';

  @override
  String get settings_call_codecs_preferred_video_tip =>
      'O codec de vídeo preferencial é usado nas chamadas de vídeo. Se o codec não for suportado pelo dispositivo, a chamada será estabelecida com o próximo codec disponível.';

  @override
  String get settings_call_codecs_preferred_video_title => 'Codec de vídeo preferencial';

  @override
  String get settings_certificateVerification_Section_title => 'Verificação do certificado TURN';

  @override
  String get settings_certificateVerification_Section_tooltip =>
      'Como o certificado do servidor de relay é verificado. Altere isso somente se as chamadas não conectarem e o suporte tiver solicitado.';

  @override
  String get settings_certificateVerification_verify => 'Verificar';

  @override
  String get settings_certificateVerification_disabled => 'Não verificar';

  @override
  String get settings_certificateVerification_warning =>
      'Sem a verificação, a conexão com o servidor de relay pode ser interceptada. O áudio e o vídeo das chamadas continuam criptografados de qualquer forma. Reative-a assim que o servidor for corrigido.';

  @override
  String get settings_speakerOnMinimize_Section_title => 'Viva-voz ao sair da chamada';

  @override
  String get settings_speakerOnMinimize_Section_tooltip =>
      'Define se uma chamada de áudio passa para o alto-falante quando você sai da tela da chamada e volta para o fone do aparelho quando você retorna a ela.';

  @override
  String get settings_media_Watch_onPhone =>
      'Qualidade personalizada, processamento de áudio, vídeo, ICE e TURN: no telefone';

  @override
  String get settings_media_Watch_resetQuestion => 'Redefinir todas as configurações de mídia para o padrão?';

  @override
  String get settings_speakerOnMinimize_switch => 'Ativar o viva-voz ao sair da tela da chamada';

  @override
  String settings_Watch_onPhone(String setting) {
    return '$setting: no telefone';
  }

  @override
  String get settings_callerId_cancel_button => 'Cancelar';

  @override
  String get settings_callerId_defaultTitle => 'Identificador de chamadas padrão';

  @override
  String get settings_callerId_dialcode => 'Código de discagem:';

  @override
  String get settings_callerId_dialCodeMatching_title => 'Regras por código de discagem';

  @override
  String get settings_callerId_duplicate_dialcode_error => 'Escolha outro código de discagem, este já está em uso.';

  @override
  String get settings_callerId_number => 'Número:';

  @override
  String get settings_callerId_number_hint => 'Selecione um número';

  @override
  String get settings_callerId_save_button => 'Salvar';

  @override
  String get settings_connectionSection_title => 'Conexão e comportamento das chamadas';

  @override
  String get settings_connectionSection_tooltip =>
      'Configure como o seu dispositivo trata o estabelecimento da conexão, a negociação de mídia e as atualizações da chamada durante a comunicação ponto a ponto.';

  @override
  String get settings_encoding_AppBar_reset_tooltip => 'Redefinir para o padrão';

  @override
  String get settings_encoding_Section_audio_ptime => 'Ptime de áudio desejado: ';

  @override
  String get settings_encoding_Section_audio_ptime_limit => 'Limite de ptime de áudio: ';

  @override
  String get settings_encoding_Section_bandwidth_prefix => 'Taxa de amostragem: ';

  @override
  String get settings_encoding_Section_bitrate_prefix => 'Taxa de bits: ';

  @override
  String get settings_encoding_Section_bitrate_title => 'Configurações de taxa de bits do codec';

  @override
  String get settings_encoding_Section_bitrate_tooltip =>
      'Ajuste as configurações de taxa de bits dos codecs de áudio e vídeo: valores menores reduzem o uso de banda, mas afetam a qualidade; valores maiores aumentam a qualidade, mas também o uso de banda.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeREMBFeedback => 'Remover feedback REMB';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeREMBFeedback_tooltip =>
      'Remove do SDP as linhas de feedback RTCP goog-remb. Desativa a estimativa de banda do lado do receptor em alguns endpoints.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeTWCCFeedback => 'Remover feedback TWCC';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeTWCCFeedback_tooltip =>
      'Remove do SDP o feedback RTCP transport-cc e o extmap transport-wide-cc. Desativa o controle de congestionamento em nível de transporte.';

  @override
  String get settings_encoding_Section_rtp_extensions_title => 'Extensões RTP';

  @override
  String get settings_encoding_Section_rtp_extensions_tooltip =>
      'Desative extensões de cabeçalho RTP individuais na negociação SDP.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_twcc => 'TWCC';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_absSendTime => 'Abs-Send-Time';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_playoutDelay => 'Playout-Delay';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_videoContentType => 'Video-Content-Type';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_videoTiming => 'Video-Timing';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_colorSpace => 'Color-Space';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_audioLevel => 'Audio-Level';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_tOffset => 'TOffset';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_videoOrientation => 'Video-Orientation';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_rtpStreamId => 'RTP-Stream-ID';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeExtmap_repairedRtpStreamId => 'Repaired-RTP-Stream-ID';

  @override
  String get settings_encoding_Section_extra_sdp_mod_remapTE8 => 'Remapear o código TE_8k para 101';

  @override
  String get settings_encoding_Section_extra_sdp_mod_remapTE8_tooltip =>
      'Altera o payload type de TE8 para 101 no SDP para melhorar a compatibilidade com alguns endpoints SIP.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeStaticRtpmaps => 'Remover linhas rtpmap estáticas';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeStaticRtpmaps_tooltip =>
      'Remove do SDP as linhas rtpmap estáticas dos codecs de áudio (por exemplo, PCMU, PCMA) para reduzir o tamanho do SDP. Pode ajudar com problemas de fragmentação por MTU em alguns endpoints SIP.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_title => 'Modificações adicionais do SDP';

  @override
  String get settings_encoding_Section_measure_hz => 'Hz';

  @override
  String get settings_encoding_Section_measure_kbps => 'Kbps';

  @override
  String get settings_encoding_Section_measure_ms => 'ms';

  @override
  String get settings_encoding_Section_opus_bandwidth => 'Substituição da largura de banda: ';

  @override
  String get settings_encoding_Section_opus_bitrate => 'Substituição da taxa de bits: ';

  @override
  String get settings_encoding_Section_opus_channels => 'Substituição do modo de canais: ';

  @override
  String get settings_encoding_Section_opus_dtx => 'Substituição do modo DTX: ';

  @override
  String get settings_encoding_Section_opus_samplingRate => 'Substituição da taxa de amostragem: ';

  @override
  String get settings_encoding_Section_opus_title => 'Ajuste do codec Opus';

  @override
  String get settings_encoding_Section_opus_tooltip =>
      'Ajuste as configurações específicas do codec Opus. Pode ser usado para reduzir o uso de banda ou melhorar a qualidade do áudio';

  @override
  String get settings_encoding_Section_packetization_title => 'Empacotamento de áudio';

  @override
  String get settings_encoding_Section_packetization_tooltip =>
      'Ajuste o tempo de empacotamento do áudio em milissegundos; pode ser usado para reduzir a latência do áudio ou corrigir problemas de tamanho de MTU da rede';

  @override
  String get settings_encoding_Section_packetization_warning_title => 'Aviso:';

  @override
  String get settings_encoding_Section_packetization_warning_message =>
      'Alguns codecs podem ter dificuldades com valores de ptime fora do padrão, causando falhas audíveis ou silêncio. Use somente se souber o que está fazendo.';

  @override
  String get settings_encoding_Section_preset => 'Predefinição';

  @override
  String get settings_encoding_Section_preset_balance => 'Equilibrado';

  @override
  String get settings_encoding_Section_preset_balance_tooltip => 'Equilibra a qualidade da chamada com o uso de dados.';

  @override
  String get settings_encoding_Section_preset_eco => 'Baixa largura de banda';

  @override
  String get settings_encoding_Section_preset_eco_tooltip =>
      'Usa menos dados de internet e funciona melhor em conexões lentas ou instáveis.';

  @override
  String get settings_encoding_Section_preset_custom => 'Personalizado';

  @override
  String get settings_encoding_Section_preset_custom_tooltip =>
      'Ajuste manualmente as configurações de qualidade da chamada.';

  @override
  String get settings_encoding_Section_preset_default => 'Recomendado';

  @override
  String get settings_encoding_Section_preset_default_tooltip =>
      'As configurações padrão de qualidade de mídia escolhidas para este aplicativo. Funcionam bem para a maioria das chamadas';

  @override
  String get settings_encoding_Section_preset_bypass => 'Modo de compatibilidade';

  @override
  String get settings_encoding_Section_preset_bypass_tooltip =>
      'Não aplica as configurações de qualidade de mídia e usa o estabelecimento de chamada sem modificações. Ajuda a resolver problemas de compatibilidade.';

  @override
  String get settings_encoding_Section_preset_full_flex => 'Full Flex';

  @override
  String get settings_encoding_Section_preset_quality => 'Melhor qualidade';

  @override
  String get settings_encoding_Section_preset_quality_tooltip =>
      'Oferece a melhor qualidade de áudio e vídeo. Requer uma conexão de internet rápida e estável.';

  @override
  String get settings_encoding_Section_preset_title => 'Configurações de codificação de mídia';

  @override
  String get settings_encoding_Section_preset_tooltip =>
      'Predefinições de ajuste dos codecs de áudio e vídeo: valores menores reduzem o uso de banda, mas afetam a qualidade; valores maiores aumentam a qualidade, mas também o uso de banda. A predefinição padrão traz as configurações recomendadas pelo seu fornecedor de acordo com as preferências do ambiente dele.';

  @override
  String get settings_encoding_Section_ptime_prefix => 'Ptime: ';

  @override
  String get settings_encoding_Section_rtp_override_audio => 'Substituição dos perfis de áudio';

  @override
  String get settings_encoding_Section_rtp_override_conference => 'Substituição dos perfis de áudio da conferência';

  @override
  String get settings_encoding_Section_rtp_override_title => 'Ativar/desativar e reordenar perfis RTP';

  @override
  String get settings_encoding_Section_rtp_override_tooltip =>
      'Pode ser usado para substituir a ordem de prioridade dos perfis RTP de áudio e vídeo ou excluir alguns perfis da lista de negociação SDP. Isso permite forçar o uso de codecs específicos ou excluir codecs com suporte deficiente no dispositivo, na rede ou no sistema remoto';

  @override
  String get settings_encoding_Section_rtp_override_video => 'Substituição dos perfis de vídeo';

  @override
  String get settings_encoding_Section_rtp_override_warning_message =>
      'A substituição pode afetar a compatibilidade com outros dispositivos ou sistemas de mídia e causar erros nas chamadas; use somente se souber o que está fazendo.';

  @override
  String get settings_encoding_Section_rtp_override_warning_title => 'Aviso:';

  @override
  String get settings_encoding_Section_target_audio_bitrate => 'Taxa de bits de áudio desejada: ';

  @override
  String get settings_encoding_Section_target_video_bitrate => 'Taxa de bits de vídeo desejada: ';

  @override
  String get settings_encoding_Section_value_auto => 'Automático';

  @override
  String get settings_encoding_Section_value_disable => 'Desativar';

  @override
  String get settings_encoding_Section_value_enable => 'Ativar';

  @override
  String get settings_encoding_Section_value_mono => 'Mono';

  @override
  String get settings_encoding_Section_value_off => 'Desativado';

  @override
  String get settings_encoding_Section_value_on => 'Ativado';

  @override
  String get settings_encoding_Section_value_stereo => 'Estéreo';

  @override
  String get settings_iceSettings_Section_netfilter_skipv4 => 'Ignorar candidatos IPv4';

  @override
  String get settings_iceSettings_Section_netfilter_skipv6 => 'Ignorar candidatos IPv6';

  @override
  String get settings_iceSettings_Section_netfilter_title => 'Protocolo de rede';

  @override
  String get settings_iceSettings_Section_noskip => 'Sem filtragem';

  @override
  String get settings_iceSettings_Section_title => 'Filtragem de candidatos ICE';

  @override
  String get settings_iceSettings_Section_tooltip =>
      'Filtrar os candidatos ICE de acordo com as preferências de rede pode ajudar a evitar problemas de rede';

  @override
  String get settings_iceSettings_Section_trfilter_skipTcp => 'Ignorar candidatos TCP';

  @override
  String get settings_iceSettings_Section_trfilter_skipUdp => 'Ignorar candidatos UDP';

  @override
  String get settings_iceSettings_Section_trfilter_title => 'Protocolo de transporte';

  @override
  String get settings_ListViewTileSubtitle_registeredNeedsConnection => 'Requer conexão';

  @override
  String get settings_ListViewTileSubtitle_registeredOff => 'As chamadas recebidas são rejeitadas';

  @override
  String get settings_ListViewTileSubtitle_registeredOn => 'A conta pode receber chamadas';

  @override
  String get settings_ListViewTileSubtitle_registeredUpdating => 'Atualizando...';

  @override
  String get settings_ListViewTileSubtitle_registeredWaitingForConnection => 'Aguardando a conexão...';

  @override
  String get settings_ListViewTileTitle_about => 'Sobre';

  @override
  String get settings_ListViewTileTitle_accountDelete => 'Excluir conta';

  @override
  String get settings_ListViewTileTitle_call_codecs => 'Codecs de chamada';

  @override
  String get settings_ListViewTileTitle_cacheManagement => 'Armazenamento e cache';

  @override
  String get settings_ListViewTileTitle_callerId => 'Identificador de chamadas';

  @override
  String get settings_ListViewTileTitle_encoding => 'Codificação de mídia';

  @override
  String get settings_ListViewTileTitle_features => 'SERVIÇOS';

  @override
  String get settings_ListViewTileTitle_help => 'Ajuda';

  @override
  String get settings_ListViewTileTitle_language => 'Idioma';

  @override
  String get settings_ListViewTileTitle_logout => 'Sair';

  @override
  String get settings_ListViewTileTitle_logRecordsConsole => 'Console de registros de log';

  @override
  String get settings_ListViewTileTitle_mediaSettings => 'Configurações de mídia';

  @override
  String get settings_ListViewTileTitle_network => 'Configurações de rede';

  @override
  String get settings_ListViewTileTitle_presence => 'Presença SIP';

  @override
  String get settings_ListViewTileTitle_registered => 'Online';

  @override
  String get settings_ListViewTileTitle_self_config => 'Página de autoconfiguração';

  @override
  String get settings_ListViewTileTitle_callCenter => 'Call center';

  @override
  String get settings_ListViewTileTitle_sessions => 'Sessões';

  @override
  String get settings_ListViewTileTitle_settings => 'CONFIGURAÇÕES';

  @override
  String get settings_ListViewTileTitle_termsConditions => 'Termos e condições';

  @override
  String get settings_ListViewTileTitle_themeMode => 'Tema';

  @override
  String get settings_ListViewTileTitle_toolbox => 'FERRAMENTAS';

  @override
  String get settings_ListViewTileTitle_voicemail => 'Correio de voz';

  @override
  String get settings_LogoutConfirmDialog_content => 'Tem certeza de que deseja sair?';

  @override
  String get settings_LogoutConfirmDialog_title => 'Confirmar saída';

  @override
  String get settings_missingMicrophoneIndicator_title =>
      'Falta a permissão do microfone. Não é possível fazer chamadas.';

  @override
  String get settings_network_Watch_howTheyDiffer => 'Qual é a diferença';

  @override
  String get settings_network_incomingCallType_pushNotification_description =>
      'Quando não está em uso, o app para de ser executado e consome o mínimo de recursos, o que ajuda a economizar bateria. Ao chegar uma chamada, o servidor envia uma notificação push ao telefone, e o sistema operacional abre o app para tratar a chamada. No entanto, esse método não garante que todas as chamadas sejam recebidas. Se o telefone ficar inativo por um período prolongado, algumas versões do Android podem limitar as notificações push, o que pode fazer você perder uma chamada.';

  @override
  String get settings_network_incomingCallType_pushNotification_title => 'Notificação push';

  @override
  String get settings_network_incomingCallType_socket_description =>
      'O app continua sendo executado em segundo plano e mantém sempre uma conexão ativa com o servidor. Isso aumenta as chances de receber uma chamada, mas pode consumir a bateria mais rapidamente.';

  @override
  String get settings_network_incomingCallType_socket_title => 'Conexão persistente com o servidor';

  @override
  String get settings_network_incomingCallType_title => 'Entrega de chamadas recebidas';

  @override
  String get settings_registerStatusSnackBar_requestFailed => 'Não foi possível acessar o servidor - tente novamente';

  @override
  String get settings_registerStatusSnackBar_unavailable =>
      'Sem conexão com o servidor - esta configuração não pode ser alterada agora';

  @override
  String get settings_videoCapturing_Section_framerate_prefix => 'quadros: ';

  @override
  String get settings_videoCapturing_Section_framerate_title => 'Taxa de quadros da imagem';

  @override
  String get settings_videoCapturing_Section_resolution_prefix => 'pontos verticais: ';

  @override
  String get settings_videoCapturing_Section_resolution_title => 'Resolução da imagem';

  @override
  String get settings_videoCapturing_Section_title => 'Captura de vídeo';

  @override
  String get settings_videoCapturing_Section_tooltip =>
      'Pode ser usado para ajustar a qualidade do vídeo a necessidades ou ambientes específicos.';

  @override
  String get settings_videoOffer_option_ignore =>
      'Responder sem vídeo\nNenhuma faixa será adicionada, a menos que seja negociada depois.';

  @override
  String get settings_videoOffer_option_includeInactive =>
      'Incluir faixa de vídeo inativa\nGarante a compatibilidade com ofertas de vídeo para ativação futura.';

  @override
  String get settings_videoOffer_title => 'Defina como este dispositivo responde a uma oferta que inclui vídeo.';

  @override
  String get signalingResponseCode_ambiguousRequest => 'Não foi possível entender sua solicitação.';

  @override
  String get signalingResponseCode_busyEverywhere =>
      'O usuário que você está tentando contatar está ocupado. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_callNotExist => 'A solicitação não corresponde a nenhum diálogo ou transação.\n';

  @override
  String get signalingResponseCode_declineCall => 'A chamada foi recusada.';

  @override
  String get signalingResponseCode_errorAttachingPlugin =>
      'Tivemos um problema ao conectar um recurso. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_errorDetachingPlugin =>
      'Tivemos um problema ao desconectar um recurso. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_errorSendingMessage =>
      'Não foi possível enviar sua mensagem. Verifique sua rede e tente novamente.';

  @override
  String get signalingResponseCode_exchangeRoutingError =>
      'Não foi possível encontrar uma rota para concluir sua solicitação. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_handleNotFound => 'Não encontramos o que você estava procurando. Tente novamente.';

  @override
  String get signalingResponseCode_incompatibleDestination =>
      'O destino que você está tentando contatar é incompatível.';

  @override
  String get signalingResponseCode_invalidElementType => 'Algo não está certo. Tente novamente.';

  @override
  String get signalingResponseCode_invalidJson => 'Ocorreu um erro ao processar seus dados. Tente novamente.';

  @override
  String get signalingResponseCode_invalidJsonObject =>
      'Algumas das informações fornecidas não são válidas. Confira e tente novamente.';

  @override
  String get signalingResponseCode_invalidNumberFormat => 'Formato de número inválido';

  @override
  String get signalingResponseCode_invalidPath => 'A ação solicitada não está disponível. Tente outra opção.';

  @override
  String get signalingResponseCode_invalidSdp => 'Encontramos um erro técnico. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_invalidStream => 'O fluxo solicitado não está disponível. Tente novamente.';

  @override
  String get signalingResponseCode_loopDetected => 'Detectamos um loop na chamada. Tente novamente.';

  @override
  String get signalingResponseCode_missingMandatoryElement =>
      'Faltam informações obrigatórias. Preencha todos os campos obrigatórios.';

  @override
  String get signalingResponseCode_missingRequest => 'Algo deu errado com sua solicitação. Tente novamente.';

  @override
  String get signalingResponseCode_normalUnspecified => 'Ocorreu um erro. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_notAcceptable =>
      'A chamada foi marcada como não aceitável. Verifique suas rotas de saída!';

  @override
  String get signalingResponseCode_notAcceptingNewSessions =>
      'Não é possível iniciar novas sessões no momento. Tente mais tarde.';

  @override
  String get signalingResponseCode_notFoundRoutesInReplyFromBE =>
      'Não foi possível encontrar uma rota para concluir sua solicitação. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_pluginNotFound => 'Falta um componente necessário. Tente reiniciar o app.';

  @override
  String get signalingResponseCode_rejected => 'Chamada rejeitada';

  @override
  String get signalingResponseCode_requestTerminated => 'Sua solicitação foi encerrada. Tente novamente.';

  @override
  String get signalingResponseCode_sessionIdInUse => 'Esta sessão já está ativa. Tente usar outra sessão.';

  @override
  String get signalingResponseCode_sessionNotFound => 'Sua sessão não foi encontrada. Entre e tente novamente.';

  @override
  String get signalingResponseCode_tokenNotFound => 'Seu token de acesso está ausente ou é inválido. Entre novamente.';

  @override
  String get signalingResponseCode_transportSpecificError =>
      'Ocorreu um problema de conexão. Verifique sua rede e tente novamente.';

  @override
  String get signalingResponseCodeType_callHangup => 'A chamada foi encerrada.';

  @override
  String get signalingResponseCodeType_plugin =>
      'Um recurso necessário não está funcionando corretamente. Tente reiniciar o app.';

  @override
  String get signalingResponseCodeType_request => 'Há um problema com sua solicitação. Tente novamente.';

  @override
  String get signalingResponseCodeType_session => 'Há um problema com sua sessão. Entre novamente ou reinicie o app.';

  @override
  String get signalingResponseCodeType_token => 'Seu token de acesso não é válido. Entre novamente.';

  @override
  String get signalingResponseCodeType_transport =>
      'Estamos com dificuldade para nos comunicar com o servidor. Verifique sua conexão e tente novamente.';

  @override
  String get signalingResponseCodeType_unauthorized =>
      'Você não tem a autorização necessária. Entre ou entre em contato com o suporte.';

  @override
  String get signalingResponseCodeType_unknown => 'Ocorreu um problema inesperado. Tente novamente mais tarde.';

  @override
  String get signalingResponseCodeType_webrtc => 'Há um problema com a conexão da chamada. Desligue e tente novamente.';

  @override
  String get signalingResponseCode_unauthorizedAccess =>
      'Você não tem permissão para acessar este recurso. Entre em contato com o suporte se acreditar que isso é um erro.';

  @override
  String get signalingResponseCode_unauthorizedRequest =>
      'Sua solicitação não pôde ser autorizada. Tente entrar novamente.';

  @override
  String get signalingResponseCode_unexpectedAnswer => 'Recebemos uma resposta inesperada. Tente novamente.';

  @override
  String get signalingResponseCode_unknownError => 'Ocorreu um erro inesperado. Tente novamente mais tarde.';

  @override
  String get signalingResponseCode_unknownRequest =>
      'Não reconhecemos essa solicitação. Tente novamente ou entre em contato com o suporte.';

  @override
  String get signalingResponseCode_unsupportedJsepType => 'Esta ação não é suportada pela sua configuração atual.';

  @override
  String get signalingResponseCode_unwanted => 'O destinatário marcou a chamada como indesejada.';

  @override
  String get signalingResponseCode_userBusy => 'Usuário ocupado';

  @override
  String get signalingResponseCode_userNotExist => 'O usuário não existe';

  @override
  String get signalingResponseCode_unableToComplete => 'Não foi possível completar a chamada.';

  @override
  String get signalingResponseCode_wrongWebrtcState =>
      'Ocorreu um erro relacionado à chamada. Desligue e tente novamente.';

  @override
  String get socketError_connectionRefused => 'Conexão recusada';

  @override
  String get socketError_connectionRefusedDescription =>
      'O servidor recusou a conexão. Ele pode estar fora do ar ou rejeitando solicitações. Tente novamente mais tarde.';

  @override
  String get socketError_connectionReset => 'Conexão redefinida';

  @override
  String get socketError_connectionResetDescription => 'A conexão foi redefinida pelo servidor. Tente novamente.';

  @override
  String get socketError_connectionTimedOut => 'Tempo limite da conexão excedido';

  @override
  String get socketError_connectionTimedOutDescription =>
      'O tempo limite da conexão foi excedido. Isso pode acontecer por causa de uma conexão de internet lenta ou instável. Verifique sua conexão e tente novamente.';

  @override
  String get socketError_default => 'Erro de rede';

  @override
  String socketError_defaultDescription(int? errorCode) {
    return 'Ocorreu um erro de rede inesperado (código do erro: $errorCode). Isso pode ser causado por problemas de rede ou do servidor. Tente novamente mais tarde.';
  }

  @override
  String get socketError_networkUnreachable => 'Rede inacessível';

  @override
  String get socketError_networkUnreachableDescription =>
      'A rede está inacessível. Isso pode ocorrer por causa de uma conexão de internet fraca, de restrições de rede, como firewalls, ou de configurações de DNS incorretas. Se você estiver em uma rede corporativa ou restrita, entre em contato com o administrador da rede ou tente usar outra rede.';

  @override
  String get socketError_serverUnreachable => 'O servidor está inacessível devido a problemas de rede';

  @override
  String get socketError_serverUnreachableDescription =>
      'O servidor está inacessível. Isso pode ocorrer por falta de conexão com a internet ou por manutenção do servidor. Verifique sua conexão com a internet e tente novamente.';

  @override
  String get system_notifications_screen_list_empty => 'Nenhuma notificação ainda';

  @override
  String get system_notifications_Watch_deleteQuestion => 'Excluir esta notificação?';

  @override
  String get system_notifications_Watch_deleteContent => 'Ela é excluída da sua conta, não apenas deste relógio.';

  @override
  String get system_notifications_screen_title => 'Notificações';

  @override
  String get system_notifications_Dialog_deleteAllContent =>
      'Elas serão excluídas da sua conta, não apenas deste dispositivo. Esta ação não pode ser desfeita.';

  @override
  String system_notifications_Dialog_deleteAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count notificações?',
      one: 'Excluir $count notificação?',
    );
    return '$_temp0';
  }

  @override
  String get system_notifications_SemanticsAction_delete => 'Excluir';

  @override
  String get system_notifications_SemanticsLabel_deleteAll => 'Excluir todas as notificações';

  @override
  String get themeMode_dark => 'Escuro';

  @override
  String get themeMode_light => 'Claro';

  @override
  String get themeMode_system => 'Sistema';

  @override
  String get undefined_autoprovision_invalidToken =>
      'As credenciais de configuração automática foram rejeitadas pelo servidor. Solicite um novo link de configuração';

  @override
  String get undefined_autoprovision_invalidToken_title => 'Configuração inválida';

  @override
  String get undefined_stackScreenNotSupported => 'Recurso não suportado. Entre em contato com o administrador.';

  @override
  String get undefined_stackScreenNotSupported_title => 'Recurso não suportado';

  @override
  String get user_agreement_agrement_link => 'Os termos e condições do acordo';

  @override
  String get user_agreement_button_text => 'Continuar';

  @override
  String get user_agreement_terms_button_text => 'Ler os termos';

  @override
  String get user_agreement_toggle_text => 'Li e aceito os termos';

  @override
  String user_agreement_checkbox_text(Object url) {
    return 'Li $url e concordo com seus termos.';
  }

  @override
  String user_agreement_description(Object appName) {
    return 'Bem-vindo ao $appName';
  }

  @override
  String get validationBlankError => 'Informe um valor';

  @override
  String get voicemail_Cache_description =>
      'Ao reproduzir uma mensagem do correio de voz, uma cópia local do áudio é mantida para repetições imediatas. A limpeza libera espaço; o áudio é baixado novamente na próxima vez que a mensagem for reproduzida.';

  @override
  String get voicemail_Cache_title => 'Áudio do correio de voz';

  @override
  String get voicemail_Description_notSupported =>
      'O recurso de correio de voz não é suportado pelo seu core. Entre em contato com o administrador para mais informações.';

  @override
  String get voicemail_Dialog_deletePermanentlyContent =>
      'Esta mensagem será removida da sua caixa postal e não poderá ser restaurada.';

  @override
  String get voicemail_Dialog_deletePermanentlyTitle => 'Excluir permanentemente?';

  @override
  String get voicemail_Dialog_deleteSelectedContent =>
      'As mensagens de voz selecionadas serão excluídas permanentemente. Deseja continuar?';

  @override
  String get voicemail_Dialog_deleteSelectedPermanentlyContent =>
      'As mensagens selecionadas serão removidas da sua caixa postal e não poderão ser restauradas.';

  @override
  String voicemail_Dialog_deleteSelectedPermanentlyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Excluir $count mensagens permanentemente?',
      one: 'Excluir a mensagem permanentemente?',
      zero: 'Excluir $count mensagens permanentemente?',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Dialog_deleteSelectedTitle => 'Excluir as mensagens de voz selecionadas?';

  @override
  String get voicemail_Dialog_deleteSingleContent =>
      'Esta mensagem de voz será excluída permanentemente. Deseja continuar?';

  @override
  String get voicemail_Dialog_deleteSingleTitle => 'Excluir mensagem de voz?';

  @override
  String get voicemail_Filter_all => 'Todas';

  @override
  String get voicemail_Filter_saved => 'Salvas';

  @override
  String get voicemail_Filter_trash => 'Lixeira';

  @override
  String get voicemail_Filter_unheard => 'Novas';

  @override
  String voicemail_Dialog_emptyTrashContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Todas as $count mensagens na lixeira serão removidas e o espaço que elas ocupam será liberado.',
      one: 'A mensagem na lixeira será removida e o espaço que ela ocupa será liberado.',
      zero: 'Todas as $count mensagens na lixeira serão removidas e o espaço que elas ocupam será liberado.',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Dialog_emptyTrashTitle => 'Esvaziar a lixeira?';

  @override
  String get voicemail_Label_call => 'Ligar';

  @override
  String get voicemail_Label_delete => 'Excluir';

  @override
  String get voicemail_Label_deleteAll => 'Excluir todas as mensagens de voz?';

  @override
  String get voicemail_Label_deleteAllDescription =>
      'Esta ação excluirá permanentemente todas as suas mensagens de voz. Ela não pode ser desfeita.';

  @override
  String get voicemail_Label_deletePermanently => 'Excluir permanentemente';

  @override
  String get voicemail_Label_empty => 'Nenhuma mensagem de voz';

  @override
  String get voicemail_Label_emptySaved => 'Nenhuma mensagem salva';

  @override
  String get voicemail_Label_emptySavedHint => 'Abra o menu de uma mensagem e escolha Salvar para mantê-la aqui.';

  @override
  String get voicemail_Label_emptyTrash => 'A lixeira está vazia';

  @override
  String get voicemail_Label_emptyTrashAction => 'Esvaziar lixeira';

  @override
  String get voicemail_Label_emptyTrashHint =>
      'As mensagens movidas para cá continuam ocupando espaço na caixa postal até a lixeira ser esvaziada.';

  @override
  String get voicemail_Label_forward => 'Encaminhar';

  @override
  String get voicemail_Label_forwardAgain => 'Encaminhar novamente';

  @override
  String get voicemail_Label_forwardChoosing => 'Escolha para quem encaminhar';

  @override
  String voicemail_Label_forwardedBy(String name) {
    return 'Encaminhada por $name';
  }

  @override
  String get voicemail_Label_markAsHeard => 'Marcar como ouvida';

  @override
  String get voicemail_Label_markAsNew => 'Marcar como nova';

  @override
  String get voicemail_Label_moveToTrash => 'Mover para a lixeira';

  @override
  String voicemail_Label_notForwarded(String name) {
    return 'Não encaminhada · $name';
  }

  @override
  String get voicemail_Label_openContact => 'Abrir contato';

  @override
  String get voicemail_Label_playbackError => 'Falha na reprodução';

  @override
  String get voicemail_Label_restore => 'Restaurar';

  @override
  String get voicemail_Label_restoreSelected => 'Restaurar selecionadas';

  @override
  String get voicemail_Label_retry => 'Tentar novamente';

  @override
  String get voicemail_Label_save => 'Salvar';

  @override
  String get voicemail_Label_trashFootnote =>
      'As mensagens na lixeira continuam ocupando espaço na caixa postal até a lixeira ser esvaziada.';

  @override
  String get voicemail_Label_undo => 'Desfazer';

  @override
  String voicemail_Label_unheardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count novas', one: '$count nova');
    return '$_temp0';
  }

  @override
  String get voicemail_Label_unsave => 'Remover das salvas';

  @override
  String voicemail_SemanticsLabel_filter(String filter) {
    return 'Filtro, atualmente $filter';
  }

  @override
  String common_SemanticsValue_durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds segundos',
      one: '$seconds segundo',
    );
    return '$_temp0';
  }

  @override
  String common_SemanticsValue_durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutos',
      one: '$minutes minuto',
    );
    return '$_temp0';
  }

  @override
  String common_SemanticsValue_durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes $seconds';
  }

  @override
  String voicemail_SemanticsValue_playbackPosition(String position, String duration) {
    return '$position de $duration';
  }

  @override
  String voicemail_SemanticsLabel_forwardTo(String name) {
    return 'Encaminhar para $name';
  }

  @override
  String voicemail_SemanticsAnnouncement_selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens selecionadas',
      one: '$count mensagem selecionada',
      zero: 'Nada selecionado',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_SemanticsLabel_forwarding => 'Encaminhando';

  @override
  String get voicemail_SemanticsLabel_loading => 'Carregando';

  @override
  String get voicemail_SemanticsLabel_moreActions => 'Mais';

  @override
  String get voicemail_SemanticsLabel_pause => 'Pausar';

  @override
  String get voicemail_SemanticsLabel_play => 'Reproduzir';

  @override
  String get voicemail_SemanticsLabel_saved => 'Salva';

  @override
  String get voicemail_SemanticsLabel_undoMoveToTrash => 'Desfazer a movimentação para a lixeira';

  @override
  String voicemail_Snackbar_deleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não foi possível excluir as mensagens',
      one: 'Não foi possível excluir a mensagem',
      zero: 'Não foi possível excluir as mensagens',
    );
    return '$_temp0';
  }

  @override
  String voicemail_Snackbar_restoreFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Não foi possível restaurar as mensagens',
      one: 'Não foi possível restaurar a mensagem',
      zero: 'Não foi possível restaurar as mensagens',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Snackbar_updateFailed => 'Não foi possível atualizar a mensagem';

  @override
  String get voicemail_Snackbar_emptyTrashFailed => 'Não foi possível esvaziar a lixeira';

  @override
  String get voicemail_Snackbar_refreshFailed => 'Não foi possível atualizar a lista';

  @override
  String get voicemail_Snackbar_messageGone => 'Essa mensagem não existe mais';

  @override
  String get voicemail_Snackbar_movedToTrash => 'Movida para a lixeira';

  @override
  String voicemail_Snackbar_forwardFailed(String name) {
    return 'Não foi possível encaminhar para $name';
  }

  @override
  String voicemail_Snackbar_forwardRecipientFull(String name) {
    return '$name não pode receber mais mensagens encaminhadas';
  }

  @override
  String get voicemail_Snackbar_forwardTooLarge => 'A mensagem é grande demais para ser encaminhada';

  @override
  String get voicemail_Snackbar_forwardUnavailable => 'O encaminhamento não está disponível';

  @override
  String voicemail_Snackbar_forwarded(String name) {
    return 'Encaminhada para $name';
  }

  @override
  String get voicemail_Snackbar_contactGone => 'Esse contato não está mais na sua agenda';

  @override
  String get voicemail_Snackbar_notConfigured => 'Entre em contato com o administrador para ativar o correio de voz';

  @override
  String get voicemail_Title_notSupported => 'Recurso não suportado';

  @override
  String get voicemail_Widget_screenTitle => 'Correio de voz';

  @override
  String get webRegistration_ErrorAcknowledgeDialogActions_retry => 'Tentar novamente';

  @override
  String get webRegistration_ErrorAcknowledgeDialogActions_skip => 'Pular';

  @override
  String get webRegistration_ErrorAcknowledgeDialog_title => 'Erro de recurso web';

  @override
  String webview_defaultError_details(String description, int code) {
    return '$description (código: $code)';
  }

  @override
  String get webview_defaultError_reload => 'Recarregar';

  @override
  String get webview_defaultError_title => 'Algo deu errado';

  @override
  String get webview_sslError_details => 'Detalhes';

  @override
  String get webview_sslError_details_type => 'Tipo';

  @override
  String get webview_sslError_details_url => 'URL';

  @override
  String get webview_sslError_message => 'O certificado deste site não é confiável. A página não pode ser exibida.';

  @override
  String get webview_sslError_title => 'Sua conexão não é privada';

  @override
  String get webview_sslError_tryAgain => 'Tentar novamente';

  @override
  String get cdr_disconnectReason_unknown => 'Desconhecido';

  @override
  String get cdr_disconnectReason_validCauseCodeNotYetReceived => 'Código de causa válido ainda não recebido';

  @override
  String get cdr_disconnectReason_unallocatedNumber => 'Número não alocado (não atribuído)';

  @override
  String get cdr_disconnectReason_noRouteToSpecifiedTransitNetworkWan =>
      'Sem rota para a rede de trânsito especificada (WAN)';

  @override
  String get cdr_disconnectReason_noRouteToDestination => 'Sem rota para o destino';

  @override
  String get cdr_disconnectReason_sendSpecialInformationTone => 'enviar tom de informação especial';

  @override
  String get cdr_disconnectReason_misdialledTrunkPrefix => 'prefixo de tronco discado incorretamente.';

  @override
  String get cdr_disconnectReason_channelUnacceptable => 'Canal inaceitável';

  @override
  String get cdr_disconnectReason_callAwardedAndBeingDeliveredInAnEstablishedChannel =>
      'Chamada concedida e sendo entregue em um canal estabelecido';

  @override
  String get cdr_disconnectReason_prefix0DialedButNotAllowedPreemption =>
      'Prefixo 0 discado, mas não permitido (preempção)';

  @override
  String get cdr_disconnectReason_prefix1DialedButNotAllowedPreemptionReserved =>
      'Prefixo 1 discado, mas não permitido (preempção reservada)';

  @override
  String get cdr_disconnectReason_prefix1DialedButNotRequired => 'Prefixo 1 discado, mas não necessário';

  @override
  String get cdr_disconnectReason_moreDigitsReceivedThanAllowedCallIsProceeding =>
      'Mais dígitos recebidos do que o permitido, a chamada prossegue';

  @override
  String get cdr_disconnectReason_normalCallClearing => 'Encerramento normal da chamada';

  @override
  String get cdr_disconnectReason_userBusy => 'Usuário ocupado';

  @override
  String get cdr_disconnectReason_noUserResponding => 'Nenhum usuário respondendo';

  @override
  String get cdr_disconnectReason_noAnswerFromUser => 'Sem resposta do usuário';

  @override
  String get cdr_disconnectReason_subscriberIsAbsent => 'O assinante está ausente';

  @override
  String get cdr_disconnectReason_callRejected => 'Chamada rejeitada';

  @override
  String get cdr_disconnectReason_numberChanged => 'Número alterado';

  @override
  String get cdr_disconnectReason_reverseChargingRejected => 'Cobrança reversa rejeitada';

  @override
  String get cdr_disconnectReason_callSuspended => 'Chamada suspensa';

  @override
  String get cdr_disconnectReason_callResumed => 'Chamada retomada';

  @override
  String get cdr_disconnectReason_nonSelectedUserClearing => 'Encerramento por usuário não selecionado';

  @override
  String get cdr_disconnectReason_destinationOutOfOrder => 'Destino fora de serviço';

  @override
  String get cdr_disconnectReason_invalidNumberFormatIncompleteNumber =>
      'Formato de número inválido (número incompleto)';

  @override
  String get cdr_disconnectReason_facilityRejected => 'Facilidade rejeitada';

  @override
  String get cdr_disconnectReason_responseToStatusEnquiry => 'Resposta a STATUS ENQUIRY';

  @override
  String get cdr_disconnectReason_normalUnspecified => 'Normal, não especificado';

  @override
  String get cdr_disconnectReason_circuitOutOfOrder => 'Circuito fora de serviço';

  @override
  String get cdr_disconnectReason_noCircuitChannelAvailable => 'Nenhum circuito/canal disponível';

  @override
  String get cdr_disconnectReason_destinationUnattainableRequireVpciVciIsNotAvailable =>
      'Destino inatingível (o VPCI VCI exigido não está disponível)';

  @override
  String get cdr_disconnectReason_vpciVciAssignmentFailure => 'Falha na atribuição de VPCI VCI';

  @override
  String get cdr_disconnectReason_degradedServiceCallRateIsnNotValid =>
      'Serviço degradado (a taxa de chamadas não é válida)';

  @override
  String get cdr_disconnectReason_networkWanOutOfOrder => 'Rede (WAN) fora de serviço';

  @override
  String get cdr_disconnectReason_transitDelayRangeCannotBeAchievedPermanentFrameModeIsOutOfService =>
      'A faixa de atraso de trânsito não pode ser atingida (o modo de quadro permanente está fora de serviço)';

  @override
  String get cdr_disconnectReason_throughputRangeCannotBeAchievedPermanentFrameModeIsOperational =>
      'A faixa de vazão não pode ser atingida (o modo de quadro permanente está operacional)';

  @override
  String get cdr_disconnectReason_temporaryFailure => 'Falha temporária';

  @override
  String get cdr_disconnectReason_switchingEquipmentCongestion => 'Congestionamento no equipamento de comutação';

  @override
  String get cdr_disconnectReason_accessInformationDiscarded => 'Informações de acesso descartadas';

  @override
  String get cdr_disconnectReason_requestedCircuitChannelNotAvailable => 'Circuito/canal solicitado não disponível';

  @override
  String get cdr_disconnectReason_preEmptedNoVpciVciIsAvailable => 'Preemptado (nenhum VPCI VCI disponível)';

  @override
  String get cdr_disconnectReason_precedenceCallBlocked => 'Chamada com precedência bloqueada';

  @override
  String get cdr_disconnectReason_resourceUnavailableUnspecified => 'Recurso indisponível - não especificado';

  @override
  String get cdr_disconnectReason_dspError => 'Erro de DSP';

  @override
  String get cdr_disconnectReason_qualityOfServiceUnavailable => 'Qualidade de serviço indisponível';

  @override
  String get cdr_disconnectReason_requestedFacilityNotSubscribed => 'Facilidade solicitada não contratada';

  @override
  String get cdr_disconnectReason_reverseChargingNotAllowed => 'Cobrança reversa não permitida';

  @override
  String get cdr_disconnectReason_outgoingCallsBarred => 'Chamadas de saída bloqueadas';

  @override
  String get cdr_disconnectReason_outgoingCallsBarredWithinCug => 'Chamadas de saída bloqueadas dentro do CUG';

  @override
  String get cdr_disconnectReason_incomingCallsBarred => 'Chamadas de entrada bloqueadas';

  @override
  String get cdr_disconnectReason_incomingCallsBarredWithinCug => 'Chamadas de entrada bloqueadas dentro do CUG';

  @override
  String get cdr_disconnectReason_callWaitingNotSubscribed => 'Chamada em espera não contratada';

  @override
  String get cdr_disconnectReason_bearerCapabilityNotAuthorized => 'Capacidade de portadora não autorizada';

  @override
  String get cdr_disconnectReason_bearerCapabilityNotPresentlyAvailable =>
      'Capacidade de portadora indisponível no momento';

  @override
  String get cdr_disconnectReason_inconsistancyInTheInformationAndClass =>
      'Inconsistência entre a informação e a classe';

  @override
  String get cdr_disconnectReason_serviceOrOptionNotAvailableUnspecified =>
      'Serviço ou opção indisponível, não especificado';

  @override
  String get cdr_disconnectReason_bearerServiceNotImplemented => 'Serviço de portadora não implementado';

  @override
  String get cdr_disconnectReason_channelTypeNotImplemented => 'Tipo de canal não implementado';

  @override
  String get cdr_disconnectReason_transitNetworkSelectionNotImplemented =>
      'Seleção de rede de trânsito não implementada';

  @override
  String get cdr_disconnectReason_messageNotImplemented => 'Mensagem não implementada';

  @override
  String get cdr_disconnectReason_requestedFacilityNotImplemented => 'Facilidade solicitada não implementada';

  @override
  String get cdr_disconnectReason_onlyRestrictedDigitalInformationBearerCapabilityIsAvailable =>
      'Somente a capacidade de portadora de informação digital restrita está disponível';

  @override
  String get cdr_disconnectReason_serviceOrOptionNotImplementedUnspecified =>
      'Serviço ou opção não implementado, não especificado';

  @override
  String get cdr_disconnectReason_invalidCallReferenceValue => 'Valor de referência de chamada inválido';

  @override
  String get cdr_disconnectReason_identifiedChannelDoesNotExist => 'O canal identificado não existe';

  @override
  String get cdr_disconnectReason_aSuspendedCallExistsButThisCallIdentityDoesNot =>
      'Existe uma chamada suspensa, mas esta identidade de chamada não existe';

  @override
  String get cdr_disconnectReason_callIdentityInUse => 'Identidade de chamada em uso';

  @override
  String get cdr_disconnectReason_noCallSuspended => 'Nenhuma chamada suspensa';

  @override
  String get cdr_disconnectReason_callHavingTheRequestedCallIdentityHasBeenCleared =>
      'A chamada com a identidade de chamada solicitada foi encerrada';

  @override
  String get cdr_disconnectReason_calledUserNotMemberOfCug => 'O usuário chamado não é membro do CUG';

  @override
  String get cdr_disconnectReason_incompatibleDestination => 'Destino incompatível';

  @override
  String get cdr_disconnectReason_nonExistentAbbreviatedAddressEntry => 'Entrada de endereço abreviado inexistente';

  @override
  String get cdr_disconnectReason_destinationAddressMissingAndDirectCallNotSubscribed =>
      'Endereço de destino ausente e chamada direta não contratada';

  @override
  String get cdr_disconnectReason_invalidTransitNetworkSelectionNationalUse =>
      'Seleção de rede de trânsito inválida (uso nacional)';

  @override
  String get cdr_disconnectReason_invalidFacilityParameter => 'Parâmetro de facilidade inválido';

  @override
  String get cdr_disconnectReason_mandatoryInformationElementIsMissingAalParameterIsNotSupported =>
      'Elemento de informação obrigatório ausente (o parâmetro AAL não é suportado)';

  @override
  String get cdr_disconnectReason_invalidMessageUnspecified => 'Mensagem inválida, não especificado';

  @override
  String get cdr_disconnectReason_mandatoryInformationElementIsMissing => 'Elemento de informação obrigatório ausente';

  @override
  String get cdr_disconnectReason_messageTypeNonExistentOrNotImplemented =>
      'Tipo de mensagem inexistente ou não implementado';

  @override
  String get cdr_disconnectReason_messageNotCompatibleWithCallStateOrMessageTypeNonExistentOrNotImplemented =>
      'Mensagem incompatível com o estado da chamada ou tipo de mensagem inexistente ou não implementado';

  @override
  String get cdr_disconnectReason_informationElementNonexistantOrNotImplemented =>
      'elemento de informação inexistente ou não implementado';

  @override
  String get cdr_disconnectReason_invalidInformationElementContents => 'Conteúdo do elemento de informação inválido';

  @override
  String get cdr_disconnectReason_messageNotCompatibleWithCallState => 'Mensagem incompatível com o estado da chamada';

  @override
  String get cdr_disconnectReason_recoveryOnTimerExpiry => 'Recuperação por expiração do temporizador';

  @override
  String get cdr_disconnectReason_parameterNonExistentOrNotImplementedPassedOn =>
      'parâmetro inexistente ou não implementado - repassado';

  @override
  String get cdr_disconnectReason_urecognizedParameterMessageDiscarded =>
      'Mensagem com parâmetro não reconhecido descartada';

  @override
  String get cdr_disconnectReason_protocolErrorUnspecified => 'Erro de protocolo não especificado';

  @override
  String get cdr_disconnectReason_internetworkingUnspecified => 'Interfuncionamento, não especificado';

  @override
  String get cdr_disconnectReason_nextNodeIsUnreachable => 'O próximo nó está inacessível';

  @override
  String get cdr_disconnectReason_holstTelephonyServiceProviderModuleHtspmIsOutOfService =>
      'O Holst Telephony Service Provider Module (HTSPM) está fora de serviço';

  @override
  String get cdr_disconnectReason_dtlTransitIsNotMyNodeId => 'O trânsito DTL não é o ID do meu nó';

  @override
  String get devTools_AppBarTitle => 'Ferramentas de desenvolvimento';

  @override
  String get devTools_signalingService_groupTitle => 'Serviço de sinalização';

  @override
  String get devTools_signalingService_simulateKill_title => 'Simular a interrupção do serviço';

  @override
  String get devTools_signalingService_simulateKill_subtitle =>
      'Para o serviço em primeiro plano sem desconexão controlada';

  @override
  String get devTools_signalingService_simulateKill_confirmMessage =>
      'O serviço de sinalização será interrompido imediatamente. Ele será reiniciado automaticamente se as credenciais forem válidas.';

  @override
  String get devTools_signalingService_simulateKill_confirm => 'Interromper';

  @override
  String get devTools_signalingService_simulateKill_cancel => 'Cancelar';

  @override
  String get devTools_systemInfo_groupTitle => 'Dados do servidor';

  @override
  String get devTools_systemInfo_clear_title => 'Limpar os dados do servidor armazenados';

  @override
  String get devTools_systemInfo_clear_subtitle =>
      'Fecha o app; na próxima inicialização eles são carregados primeiro, como após uma atualização';

  @override
  String get devTools_systemInfo_clear_confirmMessage =>
      'Os dados do servidor armazenados são removidos e o app é fechado. Abra-o novamente para iniciar sem eles.';

  @override
  String get devTools_systemInfo_clear_confirm => 'Limpar e fechar';

  @override
  String get devTools_systemInfo_clear_cancel => 'Cancelar';

  @override
  String get common_SemanticsLabel_refresh => 'Atualizar';

  @override
  String get common_SemanticsLabel_scrollToBottom => 'Rolar até o fim';

  @override
  String get common_SemanticsLabel_scrollToTop => 'Rolar até o início';

  @override
  String common_SemanticsValue_unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count não lidas', one: '$count não lida');
    return '$_temp0';
  }

  @override
  String common_SemanticsValue_totalCount(int count) {
    return '$count no total';
  }

  @override
  String common_SemanticsValue_selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionadas',
      one: '$count selecionada',
    );
    return '$_temp0';
  }

  @override
  String get contacts_SemanticsLabel_clearSearch => 'Limpar pesquisa';

  @override
  String get contacts_SemanticsLabel_closeSearch => 'Fechar pesquisa';

  @override
  String get messaging_SemanticsLabel_newChat => 'Iniciar uma nova conversa';

  @override
  String get messaging_SemanticsLabel_newSms => 'Escrever uma nova mensagem';

  @override
  String get messaging_SemanticsLabel_call => 'Ligar';

  @override
  String get messaging_SemanticsLabel_videoCall => 'Chamada de vídeo';

  @override
  String get messaging_SemanticsLabel_message => 'Mensagem';

  @override
  String get messaging_SemanticsLabel_send => 'Enviar';

  @override
  String get messaging_SemanticsLabel_conversationDetails => 'Detalhes da conversa';

  @override
  String get messaging_SemanticsLabel_conversationOptions => 'Opções da conversa';

  @override
  String get messaging_SemanticsLabel_muted => 'Silenciada';

  @override
  String get messaging_SemanticsLabel_replying => 'Respondendo a';

  @override
  String get messaging_SemanticsLabel_editing => 'Editando';

  @override
  String get messaging_SemanticsLabel_forwarding => 'Encaminhando';

  @override
  String get messaging_SemanticsLabel_stopReplying => 'Cancelar resposta';

  @override
  String get messaging_SemanticsLabel_stopEditing => 'Cancelar edição';

  @override
  String get messaging_SemanticsLabel_stopForwarding => 'Cancelar encaminhamento';

  @override
  String get messaging_SemanticsLabel_sendForward => 'Encaminhar a mensagem';

  @override
  String callPull_SemanticsLabel_badge(String name) {
    return 'Assumir a chamada com $name';
  }

  @override
  String callPull_SemanticsLabel_badgeSeveral(int count) {
    return 'Assumir uma de $count chamadas';
  }

  @override
  String callPull_SemanticsLabel_pickup(String name) {
    return 'Atender a chamada com $name';
  }

  @override
  String get diagnosticNetworkTest_SemanticsLabel_refresh => 'Executar o teste de rede novamente';

  @override
  String get presence_settings_statusIcon_searchHint => 'Pesquisar ícones';

  @override
  String presenceSettings_SemanticsLabel_optionInfo(String option) {
    return 'O que significa $option';
  }

  @override
  String get presenceSettings_SemanticsLabel_preset => 'Predefinição de status';

  @override
  String get presenceSettings_SemanticsLabel_pickStatusIcon => 'Escolher um ícone de status';

  @override
  String get presenceSettings_SemanticsLabel_clearStatusIcon => 'Remover o ícone de status';

  @override
  String get presenceSettings_SemanticsLabel_searchIcons => 'Pesquisar ícones';

  @override
  String get presenceSettings_SemanticsLabel_stopSearchingIcons => 'Parar de pesquisar ícones';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryRecent => 'Usados recentemente';

  @override
  String get presenceSettings_SemanticsLabel_iconCategorySmileys => 'Smileys e pessoas';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryAnimals => 'Animais e natureza';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryFoods => 'Comida e bebida';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryActivities => 'Atividades';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryTravel => 'Viagens e lugares';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryObjects => 'Objetos';

  @override
  String get presenceSettings_SemanticsLabel_iconCategorySymbols => 'Símbolos';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryFlags => 'Bandeiras';
}
