// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.g.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get account_selfCarePasswordExpired_message =>
      'Votre mot de passe self-care a expiré. Veuillez le mettre à jour via votre self-care.\nTant que le mot de passe n\'a pas été changé, l\'accès au service sera limité.';

  @override
  String get actionpad_SemanticsLabel_backspace => 'Retour arrière';

  @override
  String agoTicker_daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a $days jour',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String agoTicker_hoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'il y a $hours heures',
      one: 'il y a $hours heure',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String agoTicker_minutesAgo(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'il y a $minutes minutes',
      one: 'il y a $minutes minute',
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
      other: 'il y a $secondsString secondes',
      one: 'il y a $secondsString seconde',
      zero: 'À l\'instant',
    );
    return '$_temp0';
  }

  @override
  String get alertDialogActions_no => 'Non';

  @override
  String get alertDialogActions_ok => 'Ok';

  @override
  String get alertDialogActions_yes => 'Oui';

  @override
  String get autoprovision_errorSnackBar_invalidToken =>
      'Les identifiants d\'autoconfiguration ont été refusés par le serveur. Veuillez demander un nouveau lien de configuration';

  @override
  String get autoprovision_ReloginDialog_confirm => 'Confirmer';

  @override
  String get autoprovision_ReloginDialog_decline => 'Refuser';

  @override
  String get autoprovision_ReloginDialog_text =>
      'Voulez-vous utiliser les nouveaux identifiants d\'authentification fournis dans le lien ? Vous serez déconnecté de la session en cours.';

  @override
  String get autoprovision_ReloginDialog_title => 'Confirmation de reconnexion';

  @override
  String get autoprovision_successSnackBar_used =>
      'Vos paramètres ont été récupérés, votre application est prête à être utilisée';

  @override
  String get callCenter_AppBarTitle => 'Mes files';

  @override
  String get callCenter_Button_retry => 'Réessayer';

  @override
  String get callCenter_Snackbar_changeFailed =>
      'Impossible de modifier votre statut dans la file. Veuillez réessayer.';

  @override
  String get callCenter_Snackbar_queueGone => 'Cette file ne vous appartient plus. La liste a été actualisée.';

  @override
  String get callCenter_Snackbar_readOnly =>
      'Le serveur est en lecture seule pour le moment, le statut des files ne peut donc pas être modifié.';

  @override
  String get callCenter_Switch_allQueues => 'Toutes les files';

  @override
  String callCenter_Text_agentsOfTotal(int loggedIn, int total) {
    return '$loggedIn agents sur $total';
  }

  @override
  String get callCenter_Text_loadFailed => 'Impossible de charger vos files.';

  @override
  String callCenter_Text_callersWaiting(int count) {
    return '$count en attente';
  }

  @override
  String get callCenter_Text_callersWaitingUnknown => '— en attente';

  @override
  String callCenter_Text_loggedInOfTotal(int loggedIn, int total) {
    return 'En service sur $loggedIn files sur $total';
  }

  @override
  String get callCenter_Text_noQueues => 'Vous n\'êtes agent d\'aucune file d\'appels.';

  @override
  String get callCenter_Text_offline => 'Hors ligne';

  @override
  String get callCenter_Text_online => 'En ligne';

  @override
  String get callTileActions_contact => 'Contact';

  @override
  String get callTileActions_history => 'Historique';

  @override
  String get callTileActions_message => 'Message';

  @override
  String get cacheManagement_Button_clear => 'Effacer';

  @override
  String get cacheManagement_Label_empty => 'Aucune donnée en cache sur cet appareil';

  @override
  String cacheManagement_Label_itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '$count enregistrement',
    );
    return '$_temp0';
  }

  @override
  String get cacheManagement_Label_unknown => 'Inconnu';

  @override
  String get cacheManagement_Widget_screenTitle => 'Stockage et cache';

  @override
  String get callTileActions_more => 'Plus';

  @override
  String get call_SemanticsLabel_hideControls => 'Masquer les commandes d\'appel';

  @override
  String get call_SemanticsLabel_showControls => 'Afficher les commandes d\'appel';

  @override
  String get keypad_SemanticsLabel_number => 'Numéro de téléphone';

  @override
  String get keypad_SemanticsAction_paste => 'Coller un numéro';

  @override
  String get callCameraPreview_SemanticsLabel_switchCamera => 'Changer de caméra';

  @override
  String get callThumbnail_SemanticsAction_moveTopLeft => 'Déplacer en haut à gauche';

  @override
  String get callThumbnail_SemanticsAction_moveTopRight => 'Déplacer en haut à droite';

  @override
  String get callThumbnail_SemanticsAction_moveMiddleLeft => 'Déplacer au milieu à gauche';

  @override
  String get callThumbnail_SemanticsAction_moveMiddleRight => 'Déplacer au milieu à droite';

  @override
  String get callThumbnail_SemanticsAction_moveBottomLeft => 'Déplacer en bas à gauche';

  @override
  String get callThumbnail_SemanticsAction_moveBottomRight => 'Déplacer en bas à droite';

  @override
  String get callThumbnail_SemanticsLabel_returnToCall => 'Revenir à l\'appel';

  @override
  String callTile_SemanticsLabel_call(String name) {
    return 'Appeler $name';
  }

  @override
  String callTile_SemanticsLabel_videoCall(String name) {
    return 'Appel vidéo à $name';
  }

  @override
  String get callerId_SemanticsLabel_addMatch => 'Ajouter une correspondance d\'indicatif';

  @override
  String get callerId_SemanticsLabel_matchNumber => 'Numéro à afficher pour cet indicatif';

  @override
  String get callerId_SemanticsLabel_defaultNumber => 'Numéro à appeler par défaut';

  @override
  String callerId_SemanticsLabel_matchPrefix(String country) {
    return 'Indicatif à faire correspondre, actuellement $country';
  }

  @override
  String callerId_SemanticsLabel_removeMatch(String dialCode) {
    return 'Supprimer la correspondance pour $dialCode';
  }

  @override
  String callerId_SemanticsLabel_matchRule(String dialCode, String number) {
    return 'Les appels vers $dialCode affichent $number';
  }

  @override
  String callerId_SemanticsLabel_matchRuleWithCountry(String dialCode, String country, String number) {
    return 'Les appels vers $dialCode, $country, affichent $number';
  }

  @override
  String get call_CallActionsTooltip_accept => 'Accepter';

  @override
  String get call_CallActionsTooltip_accept_inviteToAttendedTransfer => 'Accepter le transfert';

  @override
  String get call_CallActionsTooltip_attended_transfer => 'Transfert supervisé';

  @override
  String get call_CallActionsTooltip_unattendedTransferHint => 'Transférez l\'appel sans parler d\'abord';

  @override
  String get call_CallActionsTooltip_attendedTransferHint => 'Parlez d\'abord, puis transférez l\'appel';

  @override
  String get call_CallActionsTooltip_transferToCallHint => 'Mettez-les en relation avec cet appel';

  @override
  String get call_CallActionsTooltip_transferChooseHint => 'Transférez l\'appel vers un autre numéro';

  @override
  String get call_CallActionsTooltip_addParticipantHint => 'Appelez quelqu\'un et faites-le rejoindre cet appel';

  @override
  String get call_CallActionsTooltip_addParticipantHint_conference =>
      'Appelez quelqu\'un et faites-le rejoindre la conférence';

  @override
  String get call_CallActionsTooltip_cancelInviteHint => 'Arrêtez d\'appeler et revenez à l\'appel';

  @override
  String get call_CallActionsTooltip_cancelInviteHint_conference => 'Arrêtez d\'appeler et revenez à la conférence';

  @override
  String get call_CallActionsTooltip_addOrTransfer => 'Ajouter ou transférer';

  @override
  String get call_CallActionsTooltip_addParticipant => 'Ajouter un participant';

  @override
  String call_CallActionsTooltip_cancelInvite(String name) {
    return 'Annuler l\'invitation à $name';
  }

  @override
  String get call_CallActionsTooltip_changeAudioDevice => 'Changer de périphérique audio';

  @override
  String get call_CallActionsTooltip_decline_inviteToAttendedTransfer => 'Refuser le transfert';

  @override
  String get call_CallActionsTooltip_device_bluetooth => 'Bluetooth';

  @override
  String get call_CallActionsTooltip_device_earpiece => 'Écouteur';

  @override
  String get call_CallActionsTooltip_device_speaker => 'Haut-parleur';

  @override
  String get call_CallActionsTooltip_device_streaming => 'Streaming';

  @override
  String get call_CallActionsTooltip_device_unknown => 'Périphérique inconnu';

  @override
  String get call_CallActionsTooltip_device_wiredHeadset => 'Casque filaire';

  @override
  String get call_CallActionsTooltip_disableCamera => 'Désactiver la caméra';

  @override
  String get call_CallActionsTooltip_disableSpeaker => 'Désactiver le haut-parleur';

  @override
  String get call_CallActionsTooltip_enableCamera => 'Activer la caméra';

  @override
  String get call_CallActionsTooltip_cameraPermissionDenied =>
      'Autorisation de la caméra refusée. Appuyez pour ouvrir les paramètres';

  @override
  String get call_CallActionsTooltip_enableSpeaker => 'Activer le haut-parleur';

  @override
  String get call_CallActionsTooltip_hangup => 'Raccrocher';

  @override
  String get call_CallActionsTooltip_hideKeypad => 'Masquer le clavier';

  @override
  String get call_CallActionsTooltip_hold => 'Mettre en attente';

  @override
  String get call_CallActionsTooltip_mute => 'Couper le microphone';

  @override
  String get call_CallActionsTooltip_showKeypad => 'Afficher le clavier';

  @override
  String get call_CallActionsTooltip_transfer => 'Transférer';

  @override
  String get call_CallActionsTooltip_transfer_choose => 'Choisir le numéro';

  @override
  String get call_CallActionsTooltip_unattended_transfer => 'Transfert non supervisé';

  @override
  String get call_CallActionsTooltip_unhold => 'Reprendre l\'appel';

  @override
  String get call_CallActionsTooltip_unmute => 'Réactiver le microphone';

  @override
  String get call_CallList_incoming => 'Entrant';

  @override
  String get call_CallList_outgoing => 'Sortant';

  @override
  String get conferenceRefusal_conferenceDisabled => 'Les conférences ne sont pas disponibles sur ce compte';

  @override
  String get conferenceRefusal_conferenceAlreadyActive => 'Une conférence est déjà en cours';

  @override
  String get conferenceRefusal_lineAlreadyInConference => 'Cet appel est déjà dans la conférence';

  @override
  String get conferenceRefusal_callsAreGone => 'Ces appels ne sont plus disponibles pour la fusion';

  @override
  String get conferenceRefusal_lineNotReady => 'Ce participant est encore en train de rejoindre';

  @override
  String get conferenceRefusal_unavailable => 'Impossible de fusionner les appels';

  @override
  String get call_CallList_add => 'Ajouter';

  @override
  String get call_SemanticsLabel_add => 'Ajouter les appels à la conférence';

  @override
  String get call_Text_addParticipantNoFreeLine => 'Toutes les lignes sont occupées';

  @override
  String call_CallList_outsideHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels hors de la conférence',
      one: '$count appel hors de la conférence',
    );
    return '$_temp0';
  }

  @override
  String call_ConferencePanel_header(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conférence - $count participants',
      one: 'Conférence - $count participant',
    );
    return '$_temp0';
  }

  @override
  String get call_ConferencePanel_you => 'Vous';

  @override
  String get call_ConferencePanel_hostStatus => 'Hôte';

  @override
  String get call_ConferencePanel_hostStatusAside => 'Dans un autre appel';

  @override
  String get call_ConferencePanel_participantStatus => 'Dans la conférence';

  @override
  String get call_ConferencePanel_participantMuted => 'Micro coupé pour tous';

  @override
  String get call_ConferencePanel_end => 'Terminer';

  @override
  String get call_SemanticsLabel_conferenceSelfMute => 'Couper votre microphone';

  @override
  String get call_SemanticsLabel_conferenceSelfUnmute => 'Réactiver votre microphone';

  @override
  String call_SemanticsLabel_conferenceParticipantMute(String name) {
    return 'Couper le micro de $name pour tous';
  }

  @override
  String call_SemanticsLabel_conferenceParticipantUnmute(String name) {
    return 'Réactiver le micro de $name pour tous';
  }

  @override
  String call_SemanticsLabel_conferenceParticipantHangup(String name) {
    return 'Terminer l\'appel avec $name';
  }

  @override
  String get call_SemanticsLabel_conferenceEnd => 'Terminer la conférence et tous les appels qu\'elle contient';

  @override
  String get call_CallList_merge => 'Fusionner';

  @override
  String get call_SemanticsLabel_merge => 'Fusionner les appels en une conférence';

  @override
  String call_CallList_header(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appels - appuyez pour choisir',
      one: '$count appel - appuyez pour choisir',
    );
    return '$_temp0';
  }

  @override
  String get call_CallList_statusOnCall => 'En appel';

  @override
  String call_FocusedActionHint_actingOn(String name) {
    return 'Action sur : $name';
  }

  @override
  String call_FocusedActionHint_willBeEnded(String name) {
    return 'L\'appel avec $name sera terminé';
  }

  @override
  String call_FocusedActionHint_willBeHeld(String name) {
    return 'L\'appel avec $name sera mis en attente';
  }

  @override
  String get call_ToolbarStatus_connecting => 'Connexion...';

  @override
  String get call_ToolbarStatus_reconnecting => 'Reconnexion...';

  @override
  String get call_description_held => 'En attente';

  @override
  String get call_description_peerReportsMuted => 'Votre correspondant indique que vous êtes en muet';

  @override
  String get call_description_peerReportsHostAway => 'Votre correspondant indique qu\'il est dans un autre appel';

  @override
  String get call_description_incoming => 'Appel entrant';

  @override
  String get call_description_inviteToAttendedTransfer =>
      'Vous avez été invité à rejoindre un appel de transfert supervisé';

  @override
  String get call_description_outgoing => 'Appel sortant';

  @override
  String get call_description_requestToAttendedTransfer => 'Demande de transfert';

  @override
  String get call_description_transferProcessing => 'Traitement du transfert';

  @override
  String get call_errorRegisteringSelfManagedPhoneAccount =>
      'Un problème est survenu lors de l\'enregistrement du compte téléphonique autogéré.';

  @override
  String get call_FailureAcknowledgeDialog_title => 'Échec';

  @override
  String get callProcessingStatus_answering => 'Réponse à l\'appel, veuillez patienter…';

  @override
  String get callProcessingStatus_disconnecting => 'Déconnexion de l\'appel, veuillez patienter…';

  @override
  String get callProcessingStatus_init_media => 'Initialisation des périphériques multimédias';

  @override
  String get callProcessingStatus_invite => 'Établissement de la session SIP';

  @override
  String get callProcessingStatus_preparing => 'Préparation';

  @override
  String get callProcessingStatus_ringing => 'Sonnerie';

  @override
  String get callProcessingStatus_routing => 'Acheminement de l\'appel';

  @override
  String get callProcessingStatus_signaling_connecting => 'Connexion au serveur distant';

  @override
  String get iceConnectionIssue_iceFail => 'Échec de la connexion média. Vérifiez votre réseau';

  @override
  String get iceConnectionIssue_iceFailNoIcePath => 'Échec de la connexion média. Essayez de passer à un autre réseau';

  @override
  String get iceConnectionIssue_iceFailNoIcePathViaVpn => 'Le VPN bloque peut-être l\'appel. Essayez de le désactiver';

  @override
  String get callNetworkQuality_yourAudioWeak => 'Votre audio est faible';

  @override
  String get callNetworkQuality_yourVideoWeak => 'Votre vidéo est faible';

  @override
  String get callNetworkQuality_theirAudioWeak => 'Leur audio est faible';

  @override
  String get callNetworkQuality_theirVideoWeak => 'Leur vidéo est faible';

  @override
  String get callPullBadge_dialogTitle => 'Appels disponibles';

  @override
  String get callPullBadge_pickupButtonTitle => 'Décrocher';

  @override
  String get call_settings_additional_options => 'Options supplémentaires';

  @override
  String get callStatus_appUnregistered => 'Non enregistré';

  @override
  String get callStatus_connectError => 'Erreur de connexion';

  @override
  String get callStatus_connectIssue => 'Problème de connexion';

  @override
  String get callStatus_connectivityNone => 'Aucune connexion Internet';

  @override
  String get callStatus_inProgress => 'Connexion en cours';

  @override
  String get callStatus_ready => 'Connexion établie';

  @override
  String get call_SystemErrorDialog_description =>
      'Pour reprendre les appels, un redémarrage du téléphone est nécessaire. Cela résoudra une erreur système temporaire.';

  @override
  String get callStatus_serviceUnavailable => 'Service temporairement indisponible';

  @override
  String get call_SystemErrorDialog_title => 'Erreur système';

  @override
  String get call_ThumbnailAvatar_currentlyNoActiveCall => 'Il n\'y a actuellement aucun appel en cours';

  @override
  String get call_videoBackground_actionLabel_disableBlur => 'Désactiver le flou';

  @override
  String get call_videoBackground_actionLabel_enableBlur => 'Activer le flou';

  @override
  String get call_videoView_actionLabel_cover => 'Remplir';

  @override
  String get call_videoView_actionLabel_fit => 'Ajuster';

  @override
  String get cdrs_noMissedCalls_message => 'Aucun appel manqué';

  @override
  String get cdrs_noRecentCalls_message => 'Aucun appel récent';

  @override
  String get cdrs_refreshFailed_message => 'Impossible d\'actualiser l\'historique des appels - veuillez réessayer';

  @override
  String get common_SemanticsLabel_loading => 'Chargement';

  @override
  String get common_noInternetConnection_message =>
      'Il semble que vous ne soyez pas connecté à Internet. Veuillez vérifier votre connexion et réessayer.';

  @override
  String get common_noInternetConnection_retryButton => 'Réessayer';

  @override
  String get common_noInternetConnection_title => 'Aucune connexion Internet';

  @override
  String get common_problemWithLoadingPage => 'Un problème est survenu lors du chargement de la page.';

  @override
  String contact_SemanticsLabel_addFavorite(String number) {
    return 'Ajouter $number aux favoris';
  }

  @override
  String contact_SemanticsLabel_optionInfo(String option) {
    return 'Ce que signifie $option';
  }

  @override
  String contact_SemanticsLabel_removeFavorite(String number) {
    return 'Retirer $number des favoris';
  }

  @override
  String contact_SemanticsLabel_sendEmail(String address) {
    return 'Envoyer un e-mail à $address';
  }

  @override
  String contact_SemanticsLabel_transfer(String number) {
    return 'Transférer l\'appel en cours vers $number';
  }

  @override
  String contact_SemanticsLabel_addParticipant(String number) {
    return 'Ajouter $number à l\'appel';
  }

  @override
  String contact_SemanticsLabel_attendedTransfer(String number) {
    return 'Consulter $number avant de transférer l\'appel';
  }

  @override
  String get contacts_ContactsScreen_emptyFavorites =>
      'Vous n\'avez pas encore de favoris parmi vos contacts.\nAjoutez-en depuis une fiche contact à l\'aide de l\'icône en étoile';

  @override
  String get contacts_ContactsScreen_searchSemanticsLabel => 'Rechercher des contacts';

  @override
  String get contacts_ContactsScreen_sourceSemanticsLabel => 'Source des contacts';

  @override
  String get contacts_agreement_button_text => 'Continuer';

  @override
  String get contacts_agreement_checkbox_text =>
      'J\'accepte d\'autoriser l\'application à accéder à mes contacts pour améliorer mon expérience utilisateur.';

  @override
  String get contacts_agreement_description =>
      'Avec votre autorisation, l\'application affiche les contacts de votre téléphone dans son onglet Contacts. Vous pouvez tous les partager ou seulement ceux que vous choisissez. \n\nLes données des contacts sont temporairement stockées localement sur votre appareil pour activer des fonctions comme passer des appels directement depuis l\'application. \n\nCes données ne sont ni collectées, ni transmises, ni partagées en dehors de l\'application.';

  @override
  String get contacts_agreement_title => 'Collecte de données';

  @override
  String get contacts_DestinationNumberPicker_title => 'Choisissez un numéro à appeler';

  @override
  String get contacts_ExternalTabButton_refresh => 'Actualiser';

  @override
  String get contacts_ExternalTabSnackBar_requestFailed => 'Impossible de joindre le serveur - veuillez réessayer';

  @override
  String get contacts_ExternalTabText_empty => 'Aucun contact';

  @override
  String get contacts_ExternalTabText_emptyOnSearching => 'Aucun contact trouvé';

  @override
  String get contacts_ExternalTabText_failure => 'Impossible de récupérer les contacts du PBX cloud';

  @override
  String get contacts_LocalTabButton_changeSelection => 'Modifier la sélection';

  @override
  String get contacts_LocalTabButton_contactsAgreement => 'Ouvrir les paramètres';

  @override
  String get contacts_LocalTabButton_openAppSettings => 'Autoriser l\'accès aux contacts de votre téléphone';

  @override
  String get contacts_LocalTabButton_refresh => 'Actualiser';

  @override
  String get contacts_LocalTabText_contactsAgreementFailure =>
      'Pour synchroniser vos contacts locaux, vous devez accepter l\'accord dans les paramètres.';

  @override
  String get contacts_LocalTabText_empty => 'Aucun contact';

  @override
  String get contacts_LocalTabText_emptyOnSearching => 'Aucun contact trouvé';

  @override
  String get contacts_LocalTabText_failure => 'Impossible de récupérer les contacts de votre téléphone';

  @override
  String get contacts_LocalTabText_permissionFailure =>
      'Vous n\'avez pas les autorisations nécessaires pour accéder aux contacts de votre téléphone';

  @override
  String get contactsSourceFavorites => 'Favoris';

  @override
  String get contactsSourceExternal => 'PBX cloud';

  @override
  String get contactsSourceLocal => 'Votre téléphone';

  @override
  String get contacts_LocalTabText_selectionOnly => 'Seuls les contacts que vous avez sélectionnés sont affichés';

  @override
  String get contacts_LocalTabText_selectionOnlyEmpty =>
      'Seuls les contacts que vous sélectionnez sont affichés, et aucun n\'est encore sélectionné';

  @override
  String get contacts_DialogsInfoView_title => 'Informations d\'appels (BLF) :';

  @override
  String contacts_ContactTile_inCall(Object destination) {
    return 'En appel : $destination';
  }

  @override
  String get contacts_ContactScreen_options => 'Options :';

  @override
  String get contacts_ContactScreen_presenceViaSip => 'S\'abonner au statut de l\'utilisateur via SIP (Presence)';

  @override
  String get contacts_ContactScreen_presenceViaSip_tooltip =>
      'En plus de l\'échange direct de données (app vers app), l\'abonnement via la fonction SIP-Presence permet de collecter les informations de présence auprès d\'autres user agent (téléphones de bureau, softphones autonomes, etc.). Il est recommandé de l\'activer uniquement si votre contact préfère utiliser des user agent hérités et que vous souhaitez voir son statut de présence sur tous ses appareils.';

  @override
  String get contacts_ContactScreen_dialogsViaSipBlf => 'S\'abonner aux appels en cours via SIP (BLF/Dialogs)';

  @override
  String get contacts_ContactScreen_dialogsViaSipBlf_tooltip =>
      'En plus de l\'échange direct de données (app vers app), l\'abonnement via la fonction SIP-Dialogs permet de collecter les informations sur l\'état des appels auprès d\'autres user agent (téléphones de bureau, softphones autonomes, etc.). Il est recommandé de l\'activer uniquement si votre contact préfère utiliser des user agent hérités et que vous souhaitez voir son statut d\'appel sur tous ses appareils.';

  @override
  String get copyToClipboard_floatingSnackBar => 'Texte copié';

  @override
  String get copyToClipboard_popupMenuItem => 'Copier dans le presse-papiers';

  @override
  String get database_Cache_description =>
      'Copie stockée localement des données récupérées depuis le serveur : historique des appels, liste des messages vocaux, chats et contacts. L\'effacement supprime tous les enregistrements locaux ; chaque fonction retélécharge ses données lors de la synchronisation suivante.';

  @override
  String get database_Cache_title => 'Base de données locale';

  @override
  String get default_CannotRemoveOwnerMessagingSocketException => 'Impossible de supprimer le propriétaire';

  @override
  String get default_ChatMemberNotFoundMessagingSocketException => 'Membre du chat introuvable';

  @override
  String get default_ChatNotFoundMessagingSocketException => 'Chat introuvable';

  @override
  String get default_ClientExceptionError => 'Un problème est survenu avec le client HTTP';

  @override
  String get default_ErrorDetails => 'Détails';

  @override
  String get default_ErrorMessage => 'Message d\'erreur';

  @override
  String get default_ErrorPath => 'Chemin de l\'erreur';

  @override
  String get default_ErrorTransactionId => 'ID de transaction';

  @override
  String get default_ForbiddenMessagingSocketException => 'Requête interdite';

  @override
  String get default_FormatExceptionError => 'Un problème de format de réponse est survenu';

  @override
  String get default_InternalErrorMessagingSocketException => 'Erreur interne du serveur';

  @override
  String get default_InvalidChatTypeMessagingSocketException => 'Type de chat invalide';

  @override
  String get default_JoinCrashedMessagingSocketException =>
      'Une erreur est survenue lors de l\'accès à la conversation';

  @override
  String get default_MessagingSocketException => 'Une erreur est survenue lors du traitement de la requête';

  @override
  String get default_RequestFailureError => 'Une défaillance du serveur est survenue';

  @override
  String get default_SelfAuthorityAssignmentForbiddenMessagingSocketException =>
      'L\'attribution d\'autorité à soi-même est interdite';

  @override
  String get default_SelfRemovalForbiddenMessagingSocketException => 'La suppression de soi-même est interdite';

  @override
  String get default_SmsConversationNotFoundMessagingSocketException => 'Conversation SMS introuvable';

  @override
  String get default_TimeoutExceptionError => 'Un délai d\'attente du serveur est survenu';

  @override
  String get default_TimeoutMessagingSocketException => 'La requête a expiré';

  @override
  String get default_TlsExceptionError => 'Un problème est survenu avec le protocole réseau sécurisé (TLS/SSL)';

  @override
  String get default_TypeErrorError => 'Un problème de réponse est survenu';

  @override
  String get default_UnauthorizedMessagingSocketException => 'Requête non autorisée';

  @override
  String get default_UnauthorizedRequestFailureError => 'Une requête non autorisée a échoué';

  @override
  String default_UnknownExceptionError(String error) {
    return 'Un problème inconnu est survenu : $error';
  }

  @override
  String get default_UserAlreadyInChatMessagingSocketException => 'L\'utilisateur est déjà dans le chat';

  @override
  String get diagnostic_AppBar_title => 'Diagnostic';

  @override
  String get diagnostic_battery_groupTitle => 'Batterie';

  @override
  String get diagnostic_batteryMode_optimized_description =>
      'L\'activité en arrière-plan de l\'application est gérée par le système pour économiser la batterie. Elle peut ne pas fonctionner correctement avec les appels entrants déclenchés par des notifications push.';

  @override
  String get diagnostic_batteryMode_optimized_title => 'Optimisé';

  @override
  String get diagnostic_batteryMode_restricted_description =>
      'L\'activité en arrière-plan de l\'application est fortement limitée pour préserver la batterie. Des appels entrants pourraient être manqués.';

  @override
  String get diagnostic_batteryMode_restricted_title => 'Limité';

  @override
  String get diagnostic_batteryMode_unknown_description =>
      'Le statut du mode batterie est inconnu. L\'application pourrait avoir un comportement imprévisible.';

  @override
  String get diagnostic_batteryMode_unknown_title => 'Inconnu';

  @override
  String get diagnostic_batteryMode_unrestricted_description =>
      'L\'application dispose d\'un accès complet pour fonctionner en arrière-plan sans restrictions.';

  @override
  String get diagnostic_batteryMode_unrestricted_title => 'Sans restrictions';

  @override
  String get diagnostic_battery_navigate_section => 'Accéder à la section Batterie';

  @override
  String get diagnostic_battery_tile_title => 'Mode batterie';

  @override
  String get diagnostic_callingMode_groupTitle => 'Mode d\'appel';

  @override
  String get diagnostic_callingMode_tile_title => 'Mode d\'appel';

  @override
  String get diagnostic_callingMode_standalone_title => 'Mode d\'appel limité';

  @override
  String get diagnostic_callingMode_standalone_caption =>
      'Autonome - la sonnerie et le choix du casque peuvent être limités';

  @override
  String get diagnostic_callingMode_standalone_description =>
      'Cet appareil ne prend pas en charge le framework d\'appel du système (Telecom), les appels entrants utilisent donc un service en arrière-plan limité. Les appels peuvent être retardés ou manqués lorsque le système limite les applications en arrière-plan. La sélection du casque Bluetooth ou filaire n\'est pas disponible dans ce mode.';

  @override
  String get diagnostic_fullScreenIntent_tile_title => 'Appels en plein écran';

  @override
  String get diagnostic_fullScreenIntent_navigate_section => 'Accéder à la section Notifications en plein écran';

  @override
  String get diagnostic_fullScreenIntent_groupTitle => 'Appels sur l\'écran de verrouillage';

  @override
  String get diagnostic_fullScreenIntent_caption =>
      'Les appels arrivent sous forme de notification, pas en plein écran';

  @override
  String get diagnostic_fullScreenIntent_description =>
      'Permet à un appel entrant de s\'ouvrir en plein écran par-dessus l\'écran de verrouillage et d\'être décroché sur place. Sans cette autorisation, l\'appel arrive sous forme de notification et, pour répondre depuis un écran de verrouillage protégé par un code, un schéma ou une empreinte digitale, l\'appareil demande d\'abord d\'être déverrouillé.';

  @override
  String get diagnostic_permission_camera_description =>
      'Cette application a besoin de l\'autorisation d\'accéder à la caméra pour passer des appels vidéo.';

  @override
  String get diagnostic_permission_camera_title => 'Caméra';

  @override
  String get diagnostic_permission_contacts_description =>
      'Les contacts que vous partagez sont affichés dans l\'application, afin que vous puissiez les appeler et voir qui vous appelle. Il suffit de partager une sélection de contacts.';

  @override
  String get diagnostic_permission_contacts_title => 'Contacts';

  @override
  String get diagnosticPermissionDetails_button_managePermission => 'Gérer l\'autorisation';

  @override
  String get diagnosticPermissionDetails_button_requestPermission => 'Demander l\'autorisation';

  @override
  String get diagnosticPermissionDetails_title_statusPermission => 'Statut de l\'autorisation';

  @override
  String get diagnostic_permission_microphone_description =>
      'Cette application a besoin de l\'autorisation d\'accéder au microphone pour passer des appels audio.';

  @override
  String get diagnostic_permission_microphone_title => 'Microphone';

  @override
  String get diagnostic_permission_notification_description =>
      'Permet à l\'application de déclencher les appels entrants.';

  @override
  String get diagnostic_permission_notification_title => 'Notification';

  @override
  String get diagnostic_permissionStatus_denied => 'Accès refusé';

  @override
  String get diagnostic_permissionStatus_granted => 'Accès accordé';

  @override
  String get diagnostic_permissionStatus_limited => 'Accès limité';

  @override
  String get diagnostic_permissionStatus_permanentlyDenied => 'Accès refusé définitivement';

  @override
  String get diagnostic_permissionStatus_provisional => 'Accès provisoire';

  @override
  String get diagnostic_permissionStatus_restricted => 'Accès restreint';

  @override
  String get diagnostic_specialPermissionStatus_denied => 'Accès refusé';

  @override
  String get diagnostic_specialPermissionStatus_granted => 'Accès accordé';

  @override
  String get diagnostic_specialPermissionStatus_unknown => 'Inconnu';

  @override
  String get diagnostic_xiaomi_backgroundActivityStart_description =>
      'MIUI/HyperOS empêche d\'afficher l\'écran d\'appel entrant pendant que l\'application fonctionne en arrière-plan, sauf si l\'autorisation \"Afficher les fenêtres pop-up en arrière-plan\" est accordée à cette application.';

  @override
  String get diagnostic_xiaomi_backgroundActivityStart_tile_title => 'Afficher les fenêtres pop-up en arrière-plan';

  @override
  String get diagnostic_xiaomi_groupTitle => 'Autorisations Xiaomi';

  @override
  String get diagnostic_xiaomi_navigate_section => 'Accéder à la section des autorisations de l\'écran de verrouillage';

  @override
  String get diagnostic_xiaomi_showWhenLocked_description =>
      'MIUI/HyperOS empêche d\'afficher l\'écran d\'appel entrant par-dessus l\'écran de verrouillage, sauf si l\'autorisation \"Afficher sur l\'écran de verrouillage\" est accordée à cette application.';

  @override
  String get diagnostic_xiaomi_showWhenLocked_tile_title => 'Afficher sur l\'écran de verrouillage';

  @override
  String get diagnosticPushDetails_configuration_title => 'Configuration du service de notification push';

  @override
  String get diagnosticPushDetails_errorMessage_intro => 'Quelques étapes à essayer :\n';

  @override
  String get diagnosticPushDetails_errorMessage_step1 => '1. Vérifiez que votre téléphone est connecté à Internet.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step2 =>
      '2. Si vous êtes connecté, vérifiez que votre téléphone peut accéder aux services Google en visitant un site web.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step3 =>
      '3. Patientez quelques minutes et réessayez - les serveurs de messagerie Firebase sont peut-être temporairement indisponibles.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step4 =>
      '4. Redémarrez les services Google Play pour vérifier qu\'ils fonctionnent correctement.\n';

  @override
  String get diagnosticPushDetails_errorMessage_step5 =>
      '5. Vérifiez que les services Google Play sont installés sur votre appareil.\n';

  @override
  String get diagnosticPushDetails_successMessage =>
      'Le service de notification est correctement configuré et prêt à recevoir des messages et à gérer les appels entrants.';

  @override
  String get diagnostic_pushTokenStatusType_progress => 'En cours';

  @override
  String get diagnostic_pushTokenStatusType_success => 'Service correctement configuré';

  @override
  String get diagnosticReportDialogAddNoteExpansionTileTitle => 'Ajouter une note (facultatif)';

  @override
  String get diagnosticReportDialogCancelButtonLabel => 'Annuler';

  @override
  String get diagnosticReportDialogCommentTextFieldHintText => 'Décrivez ce qui s\'est passé...';

  @override
  String get diagnosticReportDialogContent =>
      'Ce rapport contient des détails techniques pour nous aider à identifier les problèmes de connexion.';

  @override
  String get diagnosticReportDialogIncludeSystemLogsSwitchTileSubtitle =>
      'Nécessite des autorisations supplémentaires.';

  @override
  String get diagnosticReportDialogIncludeSystemLogsSwitchTileTitle => 'Inclure les journaux système';

  @override
  String get diagnosticReportDialogSendReportButtonLabel => 'Envoyer le rapport';

  @override
  String get diagnosticReportDialogTitle => 'Envoyer un rapport de diagnostic';

  @override
  String get diagnosticScreen_contacts_agreement_description =>
      'Autoriser l\'application à accéder à mes contacts pour améliorer mon expérience utilisateur.';

  @override
  String get diagnosticScreen_contacts_agreement_group_title => 'Accord';

  @override
  String get diagnosticScreen_contacts_agreement_title => 'Accord sur les contacts';

  @override
  String get diagnosticScreen_permissionsGroup_title => 'Autorisations';

  @override
  String get diagnosticScreen_pushNotificationService_title => 'Service de notification push';

  @override
  String get diagnostic_network_groupTitle => 'Réseau';

  @override
  String get diagnosticNetworkTest_status_offline => 'Hors ligne';

  @override
  String get diagnosticNetworkTest_status_reachable => 'Joignable';

  @override
  String get diagnosticNetworkTest_status_restricted => 'Restreint';

  @override
  String get diagnosticNetworkTest_status_checking => 'Vérification…';

  @override
  String get diagnosticNetworkTest_status_unreachable => 'Injoignable';

  @override
  String get diagnosticNetworkTestItem_subtitle_noNetwork => 'Aucune connexion réseau';

  @override
  String diagnosticNetworkTestItem_subtitle_publicIps(String ips) {
    return 'Publique : $ips';
  }

  @override
  String get diagnosticNetworkTestItem_subtitle_stunBlocked => 'STUN bloqué · relais disponible';

  @override
  String get diagnosticNetworkTestItem_subtitle_stunUnreachable => 'STUN injoignable · local uniquement';

  @override
  String get diagnosticNetworkTestItem_subtitle_noCandidates => 'Aucun candidat ICE collecté';

  @override
  String get diagnosticNetworkTestItem_network_wifi => 'WiFi';

  @override
  String get diagnosticNetworkTestItem_network_mobile => 'Mobile';

  @override
  String get diagnosticNetworkTestItem_network_ethernet => 'Ethernet';

  @override
  String get diagnosticNetworkTestItem_network_vpn => 'VPN';

  @override
  String get diagnosticNetworkTestDetails_title => 'Joignabilité du réseau';

  @override
  String get diagnosticNetworkTestDetails_description =>
      'Vérifie si votre appareil peut passer et recevoir des appels sur Internet en testant la connectivité réseau.\nLes candidats server-reflexive (srflx) confirment qu\'une IP publique est joignable via STUN. Les candidats relay signifient que l\'accès direct est bloqué et qu\'un serveur TURN est nécessaire. Host-only signifie que STUN est injoignable et que seules les connexions locales sont possibles.';

  @override
  String get diagnosticNetworkTestDetails_status => 'Statut';

  @override
  String get diagnosticNetworkTestDetails_candidates => 'Candidats';

  @override
  String get diagnosticNetworkTestDetails_noNetwork => 'Aucune connexion réseau';

  @override
  String get diagnosticNetworkTestDetails_noCandidates => 'Aucun candidat ICE collecté';

  @override
  String get favorites_BodyCenter_empty =>
      'Vous n\'avez actuellement aucun numéro favori.\nAjoutez des favoris depuis Contacts à l\'aide de l\'icône en étoile';

  @override
  String get favorites_DeleteConfirmDialog_content => 'Voulez-vous vraiment supprimer le numéro favori actuel ?';

  @override
  String get favorites_DeleteConfirmDialog_title => 'Confirmer la suppression';

  @override
  String get favorites_SemanticsLabel_reorderDone => 'Terminer le réordonnancement';

  @override
  String get favorites_SemanticsLabel_reorder => 'Réordonner les favoris';

  @override
  String favorites_SnackBar_deleted(String name) {
    return '$name supprimé';
  }

  @override
  String formatPhone(String style, String main, String ext) {
    String _temp0 = intl.Intl.selectLogic(style, {
      'full': '$main (poste : $ext)',
      'simple': '$main',
      'only_ext': 'poste : $ext',
      'empty': 'Aucun numéro de téléphone',
      'other': '$main',
    });
    return '$_temp0';
  }

  @override
  String get locale_default => 'Par défaut';

  @override
  String get locale_en => 'Anglais';

  @override
  String get locale_it => 'Italien';

  @override
  String get locale_uk => 'Ukrainien';

  @override
  String get locale_th => 'Thaï';

  @override
  String get locale_fr => 'Français';

  @override
  String get login_Button_coreUrlAssignProceed => 'Continuer';

  @override
  String get login_Button_otpSigninRequestProceed => 'Continuer';

  @override
  String get login_Button_otpSigninVerifyProceed => 'Vérifier';

  @override
  String get login_Button_otpSigninVerifyRepeat => 'Renvoyer le code';

  @override
  String login_Button_otpSigninVerifyRepeatInterval(int seconds) {
    return 'Renvoyer le code ($seconds s)';
  }

  @override
  String get login_Button_passwordSigninProceed => 'Continuer';

  @override
  String get login_Button_signIn => 'Se connecter';

  @override
  String get login_Button_signupRequestProceed => 'Continuer';

  @override
  String get login_Button_signUpToDemoInstance => 'S\'inscrire / se connecter';

  @override
  String get login_Button_signupVerifyProceed => 'Vérifier';

  @override
  String get login_Button_signupVerifyRepeat => 'Renvoyer le code';

  @override
  String login_Button_signupVerifyRepeatInterval(int seconds) {
    return 'Renvoyer le code ($seconds s)';
  }

  @override
  String get login_ButtonTooltip_signInToYourInstance => 'Connectez-vous à votre Cloud Backend';

  @override
  String get login_Button_customCoreShort => 'Cloud Backend';

  @override
  String login_CoreVersionUnsupportedExceptionError(String actual, String supportedConstraint) {
    return 'Une version d\'instance incompatible a été fournie, contactez l\'administrateur de votre système (actuelle : $actual, prise en charge : $supportedConstraint)';
  }

  @override
  String login_AppVersionUnsupportedExceptionError(String actual, String minSupported) {
    return 'Votre version de l\'application n\'est plus prise en charge, mettez l\'application à jour pour continuer (actuelle : $actual, minimum requis : $minSupported)';
  }

  @override
  String get login_RequestFailureAddonRequiredError =>
      'Votre compte ne donne pas accès à cette application. Contactez votre fournisseur de services';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedError =>
      'Ce compte n\'a aucun mode de contact configuré pour recevoir le code de vérification';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedPhoneError =>
      'Le compte associé à ce numéro de téléphone n\'a aucun mode de contact configuré pour recevoir le code de vérification';

  @override
  String get login_RequestFailureDeliveryChannelUnspecifiedEmailError =>
      'Le compte associé à cette adresse e-mail n\'a aucun mode de contact configuré pour recevoir le code de vérification';

  @override
  String get login_RequestFailureDeviceLimitReachedError =>
      'Limite d\'appareils atteinte. Contactez votre administrateur.';

  @override
  String get login_RequestFailureDeviceLimitStillReachedError =>
      'La limite d\'appareils est toujours atteinte. Déconnectez un autre appareil.';

  @override
  String get login_RequestFailureDeviceSwitchLimitReachedError =>
      'Limite de changement d\'appareil atteinte. Contactez votre administrateur.';

  @override
  String get login_RequestFailurePendingLoginNotFoundError =>
      'La connexion n\'a pas été terminée à temps. Reconnectez-vous.';

  @override
  String get login_RequestFailurePendingLoginSessionNotFoundError =>
      'Cet appareil est déjà déconnecté. Choisissez-en un autre.';

  @override
  String get login_RequestFailureEmptyEmailError => 'Impossible d\'envoyer le code de vérification';

  @override
  String get login_RequestFailureIdentifierIsNotValid => 'L\'identifiant est invalide ou n\'existe pas';

  @override
  String get login_RequestFailureIncorrectOtpCodeError => 'Code de vérification incorrect';

  @override
  String get login_RequestFailureOtpAlreadyVerifiedError => 'Vérification déjà effectuée';

  @override
  String get login_RequestFailureOtpExpiredError => 'Vérification expirée';

  @override
  String get login_RequestFailureOtpNotFoundError => 'Vérification introuvable';

  @override
  String get login_RequestFailureOtpVerificationAttemptsExceededError => 'Nombre de tentatives de vérification dépassé';

  @override
  String get login_RequestFailureParametersApplyIssueError => 'Les données fournies ne peuvent pas être traitées';

  @override
  String get login_RequestFailurePhoneNotFoundError => 'Numéro de téléphone introuvable';

  @override
  String get login_RequestFailureAmbiguousUserRefError =>
      'Plusieurs comptes utilisent cette adresse e-mail. Connectez-vous avec votre ID de compte (numéro de téléphone).';

  @override
  String get login_RequestFailureIncorrectCredentialsError => 'Nom d\'utilisateur ou mot de passe incorrect';

  @override
  String get login_RequestFailureUserNotFoundError => 'Utilisateur introuvable';

  @override
  String get login_RequestFailureUnconfiguredBundleIdError =>
      'L\'application n\'est pas prise en charge par votre Cloud Backend';

  @override
  String get login_SemanticsLabel_hidePassword => 'Masquer le mot de passe';

  @override
  String get login_SemanticsLabel_showPassword => 'Afficher le mot de passe';

  @override
  String get login_SupportedLoginTypeMissedExceptionError =>
      'Le Cloud Backend actuel ne prend en charge aucun type de connexion compatible avec cette application';

  @override
  String login_Text_coreUrlAssignPostDescription(Object email) {
    return 'Si vous n\'avez pas encore votre propre Cloud Backend, contactez l\'équipe commerciale à $email.';
  }

  @override
  String get login_Text_coreUrlAssignPreDescription =>
      'Pour passer des appels via votre propre système VoIP, saisissez ci-dessous l\'URL de votre Cloud Backend (tel qu\'il vous a été fourni par votre responsable de compte).';

  @override
  String get login_TextFieldLabelText_coreUrlAssign => 'Saisissez l\'URL de votre Cloud Backend';

  @override
  String get login_TextFieldLabelText_otpSigninCode => 'Saisissez le code de vérification';

  @override
  String get login_TextFieldLabelText_otpSigninUserRef => 'Saisissez votre numéro de téléphone ou votre e-mail';

  @override
  String get login_TextFieldLabelText_otpSigninUserRefPhone => 'Saisissez votre numéro de téléphone';

  @override
  String get login_TextFieldLabelText_otpSigninUserRefEmail => 'Saisissez votre e-mail';

  @override
  String get login_TextFieldLabelText_passwordSigninPassword => 'Saisissez votre mot de passe';

  @override
  String get login_TextFieldLabelText_passwordSigninUserRef => 'Saisissez votre numéro de téléphone ou votre e-mail';

  @override
  String get login_TextFieldLabelText_signupCode => 'Saisissez le code de vérification';

  @override
  String get login_TextFieldLabelText_signupEmail => 'Saisissez votre e-mail';

  @override
  String get login_Text_deviceLimitDescription =>
      'Ce compte est connecté sur autant d\'appareils qu\'il est autorisé. Déconnectez-en un pour continuer sur cet appareil.';

  @override
  String get login_Text_deviceLimitTitle => 'Limite d\'appareils atteinte';

  @override
  String get login_Text_otpSigninRequestPostDescription => '';

  @override
  String get login_Text_otpSigninRequestPreDescription => '';

  @override
  String login_Text_otpSigninVerifyPostDescriptionFromEmail(String email) {
    return 'Si vous ne voyez pas d\'e-mail avec le code de vérification de $email dans votre boîte de réception, vérifiez votre dossier de courrier indésirable.';
  }

  @override
  String get login_Text_otpSigninVerifyPostDescriptionGeneral =>
      'Si vous ne voyez pas d\'e-mail avec le code de vérification dans votre boîte de réception, vérifiez votre dossier de courrier indésirable.';

  @override
  String login_Text_otpSigninVerifyPreDescriptionUserRef(String userRef) {
    return 'Un code de vérification à usage unique a été envoyé à l\'adresse e-mail associée au numéro de téléphone ou à l\'adresse e-mail fourni.';
  }

  @override
  String get login_Text_passwordSigninPostDescription => '';

  @override
  String get login_Text_passwordSigninPreDescription => '';

  @override
  String get login_Text_signupRequestPostDescription => '';

  @override
  String get login_Text_signupRequestPostDescriptionDemo =>
      'Si vous n\'avez pas encore de compte, il sera créé automatiquement pour vous';

  @override
  String get login_Text_signupRequestPreDescription => '';

  @override
  String get login_Text_signupRequestPreDescriptionDemo => '';

  @override
  String login_Text_signupVerifyPostDescriptionFromEmail(String email) {
    return 'Si vous ne voyez pas d\'e-mail avec le code de vérification de $email dans votre boîte de réception, vérifiez votre dossier de courrier indésirable.';
  }

  @override
  String get login_Text_signupVerifyPostDescriptionGeneral =>
      'Si vous ne voyez pas d\'e-mail avec le code de vérification dans votre boîte de réception, vérifiez votre dossier de courrier indésirable.';

  @override
  String login_Text_signupVerifyPreDescriptionEmail(String email) {
    return 'Un code de vérification à usage unique a été envoyé à $email.';
  }

  @override
  String get login_Text_qrSigninScanHint => 'Scannez le code QR pour vous connecter.';

  @override
  String get login_Text_qrSigninVerifyingTitle => 'Connexion en cours...';

  @override
  String get login_Text_qrSigninVerifyingDescription => 'Code QR scanné. Vérification auprès du serveur en cours.';

  @override
  String get login_Text_qrSigninCameraPermissionTitle => 'L\'accès à l\'appareil photo est désactivé';

  @override
  String get login_Text_qrSigninCameraPermissionDescription =>
      'L\'accès à l\'appareil photo est nécessaire pour scanner un code QR. Activez-le pour continuer.';

  @override
  String get login_Button_qrSigninAllowCameraAccess => 'Continuer';

  @override
  String get login_Button_qrSigninOpenSettings => 'Ouvrir les paramètres';

  @override
  String get login_Text_qrSigninInvalidCodeError => 'Ce code QR ne peut pas être utilisé pour se connecter.';

  @override
  String get loginType_otpSignin => 'Connexion par OTP';

  @override
  String get loginType_passwordSignin => 'Connexion par mot de passe';

  @override
  String get loginType_qrSignin => 'Code QR';

  @override
  String get loginType_signup => 'Inscription';

  @override
  String get login_validationCoreUrlError => 'Veuillez saisir une URL valide';

  @override
  String get login_validationCoreUrlUnreachableError => 'Impossible de joindre le service à cette adresse';

  @override
  String get login_validationEmailError => 'Veuillez saisir une adresse e-mail valide';

  @override
  String get login_validationPhoneError => 'Veuillez saisir un numéro de téléphone valide';

  @override
  String get login_validationUserRefError => 'Veuillez saisir un numéro de téléphone ou une adresse e-mail valide';

  @override
  String get logRecordsConsole_AppBarTitle => 'Console des logs';

  @override
  String get logRecordsConsole_Button_failureRefresh => 'Actualiser';

  @override
  String get logRecordsConsole_Text_failure => 'Une erreur inattendue s\'est produite';

  @override
  String logRecordsConsole_Text_recordsCountHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Affichage des $count derniers enregistrements. Utilisez Partager pour exporter le log complet.',
      one: 'Affichage de $count enregistrement. Utilisez Partager pour exporter le log complet.',
    );
    return '$_temp0';
  }

  @override
  String get logRecordsConsole_Button_infoClose => 'J\'ai compris';

  @override
  String get logRecordsConsole_PopupMenuItem_info => 'Infos';

  @override
  String get logRecordsConsole_PopupMenuItem_clear => 'Effacer';

  @override
  String get main_Button_cancelPicking => 'Annuler';

  @override
  String get main_BottomNavigationBarItemLabel_callCenter => 'Centre d\'appels';

  @override
  String get main_BottomNavigationBarItemLabel_chats => 'Discussions';

  @override
  String get main_Text_blindTransferInitiated => 'Transfert aveugle en cours';

  @override
  String get main_Text_addParticipantInitiated => 'Choisissez qui ajouter à l\'appel';

  @override
  String get main_Text_attendedTransferInitiated => 'Choisissez qui consulter avant le transfert';

  @override
  String get main_BottomNavigationBarItemLabel_contacts => 'Contacts';

  @override
  String get main_BottomNavigationBarItemLabel_favorites => 'Favoris';

  @override
  String get main_BottomNavigationBarItemLabel_keypad => 'Clavier';

  @override
  String get main_BottomNavigationBarItemLabel_recents => 'Récents';

  @override
  String get main_BottomNavigationBarItemLabel_voicemail => 'Messagerie vocale';

  @override
  String get main_CompatibilityIssueDialogActions_logout => 'Se déconnecter';

  @override
  String get main_CompatibilityIssueDialogActions_update => 'Mettre à jour';

  @override
  String main_CompatibilityIssueDialog_contentCoreVersionUnsupportedExceptionError(
    String actual,
    String supportedConstraint,
  ) {
    return 'Version de Cloud Backend incompatible, veuillez contacter l\'administrateur de votre système.\n\nVersion de l\'instance :\n$actual\n\nVersion prise en charge :\n$supportedConstraint';
  }

  @override
  String get main_CompatibilityIssueDialog_title => 'Problème de compatibilité';

  @override
  String get main_AppUpdateRequiredDialog_title => 'Mise à jour requise';

  @override
  String get main_AppUpdateRequiredDialog_description =>
      'Votre version de l\'application n\'est plus prise en charge. Veuillez mettre à jour l\'application pour continuer.';

  @override
  String get main_AppUpdateRequiredDialog_currentVersionLabel => 'Version de l\'application';

  @override
  String get main_AppUpdateRequiredDialog_buildVersionLabel => 'Version de build';

  @override
  String main_AppUpdateRequiredDialog_currentVersionValue(String storeVersion, String appVersion) {
    return '$appVersion (compilation $storeVersion)';
  }

  @override
  String get main_AppUpdateRequiredDialog_minimumVersionLabel => 'Version minimale requise';

  @override
  String get messaging_ActionBtn_retry => 'Réessayer';

  @override
  String get messaging_ChooseContact_cancel => 'Annuler';

  @override
  String get messaging_ChooseContact_empty => 'Aucun contact trouvé';

  @override
  String get messaging_ChooseContact_title => 'Choisir le contact :';

  @override
  String get messaging_ConversationBuilders_back => 'Retour';

  @override
  String get messaging_ConversationBuilders_cancel => 'Annuler';

  @override
  String messaging_ConversationBuilders_contactExtension(String extension) {
    return 'Poste : $extension';
  }

  @override
  String get messaging_ConversationBuilders_contactOrNumberSearch_hint => 'Saisissez un nom ou un numéro de téléphone';

  @override
  String get messaging_ConversationBuilders_contactSearch_hint => 'Rechercher des contacts';

  @override
  String get messaging_ConversationBuilders_create => 'Créer';

  @override
  String get messaging_ConversationBuilders_createGroup => 'Créer un groupe';

  @override
  String get messaging_ConversationBuilders_externalContacts_heading => 'Contacts Cloud PBX';

  @override
  String get messaging_ConversationBuilders_invalidNumber_message1 =>
      'Le contact a un numéro de téléphone non valide. Il doit être au format ';

  @override
  String get messaging_ConversationBuilders_invalidNumber_message2 => '. Veuillez le corriger dans votre répertoire.';

  @override
  String get messaging_ConversationBuilders_invalidNumber_ok => 'Fermer';

  @override
  String get messaging_ConversationBuilders_invalidNumber_title => 'Numéro de téléphone non valide';

  @override
  String get messaging_ConversationBuilders_invite_heading => 'Inviter des utilisateurs :';

  @override
  String get messaging_ConversationBuilders_localContacts_heading => 'Contacts locaux';

  @override
  String get messaging_ConversationBuilders_membersHeadline => 'Membres';

  @override
  String get messaging_ConversationBuilders_nameFieldEmpty => 'Veuillez saisir un nom de groupe';

  @override
  String get messaging_ConversationBuilders_nameFieldLabel => 'Nom du groupe';

  @override
  String get messaging_ConversationBuilders_nameFieldShort => 'Le nom du groupe doit comporter au moins 3 caractères';

  @override
  String get messaging_ConversationBuilders_next_action => 'Suivant';

  @override
  String get messaging_ConversationBuilders_noContacts => 'Aucun contact ne correspond à la recherche';

  @override
  String get messaging_ConversationBuilders_numberFormatExample =>
      '+ [indicatif du pays] [indicatif de zone ou d\'opérateur] [numéro d\'abonné]';

  @override
  String get messaging_ConversationBuilders_numberSearch_errorError =>
      'Le numéro de téléphone saisi n\'est pas valide. Il doit être saisi au format : ';

  @override
  String get messaging_ConversationBuilders_numberSearch_errorHint => 'Format du numéro de téléphone : ';

  @override
  String get messaging_ConversationBuilders_title_group => 'Créer un groupe';

  @override
  String get messaging_ConversationBuilders_title_new => 'Nouvelle discussion';

  @override
  String get messaging_Conversation_failure => 'Erreur de chargement de la conversation';

  @override
  String get messaging_ConversationScreen_titleAvailable => 'disponible';

  @override
  String get messaging_ConversationScreen_titlePrefix => 'Discussion :';

  @override
  String get messaging_ConversationsScreen_chatsSearch_hint =>
      'Saisissez le nom d\'une discussion ou d\'un utilisateur';

  @override
  String get messaging_ConversationsScreen_empty => 'Aucune conversation commencée';

  @override
  String get messaging_ConversationsScreen_messages_title => 'Messages';

  @override
  String get messaging_ConversationsScreen_noNumberAlert_text =>
      'Vous devez avoir un numéro de téléphone associé à votre compte pour envoyer des SMS';

  @override
  String get messaging_ConversationsScreen_noNumberAlert_title => 'Aucun numéro de téléphone';

  @override
  String get messaging_ConversationsScreen_selectNumberSheet_title => 'Sélectionnez un numéro';

  @override
  String get messaging_ConversationsScreen_smses_title => 'SMS';

  @override
  String get messaging_ConversationsScreen_smssSearch_hint => 'Saisissez un numéro de téléphone';

  @override
  String get messaging_ConversationsScreen_unsupported =>
      'La messagerie n\'est pas prise en charge par le système distant, contactez votre administrateur pour l\'activer';

  @override
  String get messaging_Conversations_tile_empty => 'Aucun message pour l\'instant';

  @override
  String get messaging_Conversations_tile_you => 'Vous';

  @override
  String get messaging_DeleteConversationDialog_content => 'Elle sera supprimée de cet appareil et du compte.';

  @override
  String get messaging_DeleteConversationDialog_title => 'Supprimer cette conversation ?';

  @override
  String get messaging_DialogInfo_deleteAsk => 'Voulez-vous vraiment supprimer cette discussion ?';

  @override
  String get messaging_DialogInfo_deleteBtn => 'Supprimer la discussion';

  @override
  String get messaging_DialogInfo_title => 'Infos contact';

  @override
  String get messaging_GroupAuthorities_moderator => 'modérateur';

  @override
  String get messaging_GroupAuthorities_noauthorities => 'membre';

  @override
  String get messaging_GroupAuthorities_owner => 'propriétaire';

  @override
  String get messaging_GroupInfo_addUserBtnText => 'Ajouter un utilisateur';

  @override
  String get messaging_GroupInfo_deleteLeaveBtnText => 'Supprimer et quitter';

  @override
  String get messaging_GroupInfo_groupMembersHeadline => 'Membres du groupe';

  @override
  String get messaging_LeaveGroupDialog_content =>
      'Vous ne recevrez plus ses messages. La conversation reste pour les autres.';

  @override
  String get messaging_LeaveGroupDialog_title => 'Quitter ce groupe ?';

  @override
  String get messaging_GroupInfo_leaveAndDeleteAsk => 'Voulez-vous vraiment quitter et supprimer ce groupe ?';

  @override
  String get messaging_GroupInfo_leaveAsk => 'Voulez-vous vraiment quitter ce groupe ?';

  @override
  String get messaging_GroupInfo_leaveBtnText => 'Quitter le groupe';

  @override
  String get messaging_GroupInfo_makeModeratorAsk => 'Voulez-vous vraiment nommer cet utilisateur modérateur ?';

  @override
  String get messaging_GroupInfo_makeModeratorBtnText => 'Nommer modérateur';

  @override
  String get messaging_GroupInfo_removeModeratorAsk => 'Voulez-vous vraiment retirer cet utilisateur des modérateurs ?';

  @override
  String get messaging_GroupInfo_removeUserAsk => 'Voulez-vous vraiment retirer cet utilisateur du groupe ?';

  @override
  String get messaging_GroupInfo_removeUserBtnText => 'Retirer';

  @override
  String get messaging_GroupInfo_title => 'Infos groupe';

  @override
  String messaging_GroupInfo_titlePrefix(int id) {
    return 'Groupe $id';
  }

  @override
  String get messaging_GroupInfo_unmakeModeratorBtnText => 'Retirer le statut de modérateur';

  @override
  String get messaging_MessageField_hint => 'Saisissez un message';

  @override
  String get messaging_MessageListView_typingTrail => 'est en train d\'écrire...';

  @override
  String get messaging_MessageView_actionsHint => 'ouvrir les actions du message';

  @override
  String get messaging_MessageView_delete => 'Supprimer';

  @override
  String get messaging_MessageView_deleted => '[supprimé]';

  @override
  String get messaging_MessageView_edit => 'Modifier';

  @override
  String get messaging_MessageView_edited => '[modifié]';

  @override
  String get messaging_MessageView_forward => 'Transférer';

  @override
  String get messaging_MessageView_reply => 'Répondre';

  @override
  String get messaging_MessageView_textcopy => 'Copier dans le presse-papiers';

  @override
  String get messaging_MessageView_today => 'Aujourd\'hui';

  @override
  String get messaging_MessageView_yesterday => 'Hier';

  @override
  String get messaging_NotificationMute_title => 'Notifications';

  @override
  String get messaging_NotificationMute_on => 'Activées';

  @override
  String get messaging_NotificationMute_muted => 'Silencieuses';

  @override
  String messaging_NotificationMute_mutedUntil(String time) {
    return 'Silencieuses jusqu\'à $time';
  }

  @override
  String get messaging_NotificationMute_sheetTitle => 'Couper les notifications';

  @override
  String get messaging_NotificationMute_forOneHour => 'Pendant 1 heure';

  @override
  String get messaging_NotificationMute_forEightHours => 'Pendant 8 heures';

  @override
  String get messaging_NotificationMute_forTwoDays => 'Pendant 2 jours';

  @override
  String get messaging_NotificationMute_forever => 'Toujours';

  @override
  String get messaging_NotificationMute_unmute => 'Réactiver';

  @override
  String get messaging_ParticipantName_unknown => 'Utilisateur inconnu';

  @override
  String get messaging_ParticipantName_you => 'Vous';

  @override
  String get messaging_SmsSendingStatus_delivered => 'remis';

  @override
  String get messaging_SmsSendingStatus_failed => 'échoué';

  @override
  String get messaging_SmsSendingStatus_sent => 'envoyé';

  @override
  String get messaging_SmsSendingStatus_waiting => 'en attente';

  @override
  String get messaging_StateBar_connecting => 'CONNEXION';

  @override
  String get messaging_StateBar_error => 'DÉCONNEXION';

  @override
  String get messaging_StateBar_initializing => 'INITIALISATION';

  @override
  String get notifications_errorSnackBarAction_callSdpConfiguration => 'Configuration SDP non valide';

  @override
  String get notifications_errorSnackBarAction_callUserMedia => 'Vérifier';

  @override
  String get notifications_messageSnackBar_callVideoDowngraded =>
      'Réponse avec caméra désactivée - autorisation de la caméra non accordée';

  @override
  String get notifications_messageSnackBarAction_callVideoDowngraded => 'Paramètres';

  @override
  String get notifications_messageSnackBar_conferenceFailed => 'La conférence n\'a pas pu être établie';

  @override
  String get notifications_messageSnackBar_conferenceVideoLeg => 'Un appel vidéo ne peut pas rejoindre une conférence';

  @override
  String get notifications_messageSnackBar_conferenceEnded => 'La conférence est terminée, les appels continuent';

  @override
  String get notifications_errorSnackBar_activeLineBlindTransferWarning =>
      'Vous êtes déjà en ligne avec le destinataire du transfert aveugle';

  @override
  String get notifications_errorSnackBar_blindTransferFailed => 'Transfert échoué, retour à l\'appel en cours';

  @override
  String get notifications_errorSnackBar_attendedTransferDeclined => 'Refus, retour à l\'appel';

  @override
  String get notifications_errorSnackBar_attendedTransferUnanswered => 'Pas de réponse, retour à l\'appel';

  @override
  String get notifications_errorSnackBar_appOffline => 'Votre application est actuellement hors ligne';

  @override
  String get notifications_errorSnackBar_appOnline => 'Votre application est en ligne';

  @override
  String get notifications_errorSnackBar_appUnregistered =>
      'Désolé, votre application est actuellement déconnectée des serveurs principaux et ne peut donc pas appeler pour l\'instant. Allez dans les réglages, puis désactivez et réactivez l\'interrupteur d\'état en ligne pour rétablir la connexion';

  @override
  String get notifications_errorSnackBar_callConnect => 'Échec de la connexion au serveur, tentative de reconnexion';

  @override
  String get notifications_errorSnackBar_callNegotiationTimeout =>
      'Impossible d\'établir l\'appel, veuillez réessayer plus tard';

  @override
  String get notifications_errorSnackBar_generalUnableToCall =>
      'Impossible d\'établir l\'appel, veuillez réessayer plus tard';

  @override
  String get notifications_errorSnackBar_callServiceBusyLine =>
      'Impossible d\'appeler pour le moment, la ligne est occupée. Veuillez réessayer plus tard.';

  @override
  String get notifications_errorSnackBar_callSignalingClientNotConnect =>
      'Impossible d\'initier l\'appel, veuillez vérifier l\'état de la connexion';

  @override
  String get notifications_errorSnackBar_callSignalingClientSessionMissed =>
      'Erreur d\'authentification, veuillez vous reconnecter';

  @override
  String get notifications_errorSnackBar_callUndefinedLine => 'Aucune ligne disponible pour initier l\'appel';

  @override
  String get notifications_errorSnackBar_callMediaTrackSetup =>
      'Échec de l\'établissement de l\'appel, veuillez réessayer';

  @override
  String get notifications_errorSnackBar_callUserMedia =>
      'Pas d\'accès aux entrées média, vérifiez les autorisations de l\'application';

  @override
  String get notifications_errorSnackBar_callWhileOffline =>
      'Impossible d\'initier l\'appel, veuillez vérifier l\'état de la connexion';

  @override
  String get notifications_errorSnackBar_callWhileUnregistered =>
      'Vous ne pouvez pas passer d\'appels pour le moment. Vérifiez l\'état de votre compte ou contactez l\'assistance.';

  @override
  String get notifications_errorSnackBar_sessionExpired => 'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get notifications_errorSnackBar_accountNotFound =>
      'Votre compte est introuvable. Il a peut-être été désactivé ou supprimé. Veuillez contacter votre administrateur.';

  @override
  String get notifications_errorSnackBar_SignalingConnectFailed =>
      'Échec de la connexion au serveur, tentative de reconnexion';

  @override
  String notifications_errorSnackBar_signalingDisconnectWithCodeName(String codeName) {
    return 'Déconnecté du serveur avec le code : $codeName';
  }

  @override
  String notifications_errorSnackBar_signalingDisconnectWithSystemReason(String reason) {
    return 'Déconnecté du serveur pour la raison suivante : $reason';
  }

  @override
  String notifications_errorSnackBar_emergencyNumber(String number) {
    return '$number est un numéro d\'urgence et ne peut pas être appelé depuis l\'application';
  }

  @override
  String get notifications_errorSnackBarAction_emergencyNumber => 'Ouvrir le clavier';

  @override
  String get notifications_errorSnackBar_SignalingSessionMissed =>
      'Erreur d\'authentification, veuillez vous reconnecter';

  @override
  String get notifications_errorSnackBar_sipRegistrationFailed_Unavailable =>
      'L\'enregistrement auprès du système VoIP distant a échoué, le service est indisponible';

  @override
  String get notifications_errorSnackBar_sipRegistrationFailed_Unexpected =>
      'L\'enregistrement auprès du système VoIP distant a échoué pour une raison inattendue';

  @override
  String notifications_errorSnackBar_sipRegistrationFailed_WithSystemReason(String reason) {
    return 'L\'enregistrement auprès du système VoIP distant a échoué pour la raison suivante : $reason';
  }

  @override
  String get notifications_errorSnackBar_sipServiceUnavailable =>
      'Erreur d\'authentification avec le système VoIP distant';

  @override
  String get notifications_messageSnackBar_appOffline => 'Votre application est actuellement hors ligne';

  @override
  String get notifications_successSnackBar_appOnline => 'Votre application est en ligne';

  @override
  String get notifications_missedCall_title => 'Appel manqué';

  @override
  String get notifications_missedCall_unknownCaller => 'Inconnu';

  @override
  String get numberActions_audioCall => 'Appel audio';

  @override
  String numberActions_callFrom(String number) {
    return 'Appeler depuis $number';
  }

  @override
  String get numberActions_callLog => 'Voir l\'historique des appels';

  @override
  String get numberActions_chat => 'Envoyer un message';

  @override
  String get numberActions_copyCallId => 'Copier l\'ID d\'appel';

  @override
  String get numberActions_copyNumber => 'Copier le numéro';

  @override
  String get numberActions_delete => 'Supprimer';

  @override
  String get numberActions_sendSms => 'Envoyer un SMS';

  @override
  String get numberActions_transfer => 'Transférer l\'appel en cours';

  @override
  String get numberActions_videoCall => 'Appel vidéo';

  @override
  String get numberActions_viewContact => 'Voir le contact';

  @override
  String get permission_Button_notNow => 'Pas maintenant';

  @override
  String get permission_Button_request => 'Continuer';

  @override
  String get permission_fullScreenNotification_Text_optional =>
      'Vous pouvez continuer sans. Les appels entrants arriveront sous forme de notification au lieu de s\'ouvrir en plein écran et, si votre téléphone est verrouillé par un code, un schéma ou une empreinte, vous devrez le déverrouiller pour répondre depuis l\'écran de verrouillage.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step1 => 'Ouvrez les Paramètres de votre téléphone.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step2 =>
      'Allez dans \'Accès spécial aux applications\' dans la section \'Applications et notifications\'.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step3 =>
      'Recherchez et appuyez sur \'Gérer les intentions plein écran\'.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step4 =>
      'Sélectionnez l\'application pour laquelle vous voulez gérer les notifications en plein écran.';

  @override
  String get permission_manageFullScreenNotificationInstructions_step5 =>
      'Activez ou désactivez l\'autorisation pour les notifications en plein écran de cette application.';

  @override
  String get permission_manageFullScreenNotificationPermissions =>
      'Gérer les autorisations de notification en plein écran';

  @override
  String get permission_manufacturer_Button_gotIt => 'J\'ai compris';

  @override
  String get permission_manufacturer_Button_toSettings => 'Ouvrir les paramètres de l\'application';

  @override
  String get permission_manufacturer_Text_heading =>
      'Pour garantir la meilleure expérience utilisateur, l\'application doit obtenir manuellement les autorisations suivantes :';

  @override
  String get permission_manufacturer_Text_trailing => 'Les autorisations pourront être modifiées à tout moment.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip1 =>
      'Ouvrez l\'écran \"Autres autorisations\" de cette application avec le bouton ci-dessous.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip2 =>
      'Activez \"Afficher les fenêtres pop-up en arrière-plan\" pour que les appels entrants apparaissent lorsque l\'application est en arrière-plan.';

  @override
  String get permission_manufacturer_Text_xiaomi_tip3 =>
      'Activez \"Afficher sur l\'écran de verrouillage\" pour que les appels entrants apparaissent par-dessus l\'écran de verrouillage.';

  @override
  String get permission_Text_description =>
      'Pour garantir la meilleure expérience utilisateur, l\'application doit obtenir les autorisations suivantes : micro pour les appels audio, caméra pour les appels vidéo et contacts pour faciliter l\'accès à vos contacts depuis l\'application.\n\nLes autorisations pourront être modifiées à tout moment.';

  @override
  String get persistentConnectionReminderContent =>
      'Vous devez lancer manuellement l\'application au moins une fois après le redémarrage de votre téléphone pour rétablir la connexion permanente et recevoir les appels entrants.';

  @override
  String get persistentConnectionReminderTitle => 'Rappel important';

  @override
  String get batteryOptimizationWarningTitle => 'Optimisation de la batterie active';

  @override
  String get batteryOptimizationWarningContent =>
      'L\'optimisation de la batterie est active sur cet appareil. Cela peut entraîner des appels manqués lorsque l\'écran s\'éteint. Désactivez-la pour maintenir la connexion permanente.';

  @override
  String get batteryOptimizationWarningOpenSettings => 'Ouvrir les paramètres';

  @override
  String get presence_activity_appointment_name => 'En rendez-vous';

  @override
  String get presence_activity_away_name => 'Absent';

  @override
  String get presence_activity_busy_name => 'Occupé';

  @override
  String get presence_activity_doNotDisturb_name => 'Ne pas déranger';

  @override
  String get presence_activity_inTransit_name => 'En déplacement';

  @override
  String get presence_activity_meal_name => 'Au repas';

  @override
  String get presence_activity_meeting_name => 'En réunion';

  @override
  String get presence_activity_none_name => 'Aucune';

  @override
  String get presence_activity_onThePhone_name => 'Au téléphone';

  @override
  String get presence_activity_permanentAbsence_name => 'Absence permanente';

  @override
  String get presence_activity_sleeping_name => 'Endormi';

  @override
  String get presence_activity_travel_name => 'En voyage';

  @override
  String get presence_activity_vacation_name => 'En vacances';

  @override
  String get presence_badge_state_available => 'Disponible';

  @override
  String get presence_badge_state_onCall => 'En appel';

  @override
  String get presence_badge_state_registered => 'Enregistré';

  @override
  String get presence_badge_state_unavailable => 'Indisponible';

  @override
  String get presence_badge_state_unregistered => 'Non enregistré';

  @override
  String get presence_infoView_activity => 'Activité :';

  @override
  String get presence_infoView_available => 'Disponible :';

  @override
  String get presence_infoView_available_false => 'Injoignable';

  @override
  String get presence_infoView_available_true => 'Disponible';

  @override
  String get presence_infoView_client => 'Client :';

  @override
  String get presence_infoView_device => 'Appareil :';

  @override
  String get presence_infoView_localTime => 'Heure locale :';

  @override
  String get presence_infoView_note => 'Note :';

  @override
  String get presence_infoView_statusIcon => 'Icône de statut :';

  @override
  String get presence_infoView_timeZone => 'Fuseau horaire :';

  @override
  String get presence_infoView_title => 'Informations de présence :';

  @override
  String get presence_infoView_updated => 'Mis à jour :';

  @override
  String presence_infoView_source(Object source) {
    return 'Source : $source';
  }

  @override
  String get presence_infoView_source_direct => 'direct';

  @override
  String get presence_infoView_source_sip => 'sip';

  @override
  String get presence_infoView_source_sipAndDirect => 'sip et direct';

  @override
  String get presence_preset_absent_name => 'Absent';

  @override
  String get presence_preset_absent_note => 'Absent';

  @override
  String get presence_preset_appointment_name => 'Rendez-vous';

  @override
  String get presence_preset_appointment_note => 'En rendez-vous';

  @override
  String get presence_preset_available_name => 'Disponible';

  @override
  String get presence_preset_away_name => 'Absent';

  @override
  String get presence_preset_away_note => 'Absent';

  @override
  String get presence_preset_dnd_name => 'Ne pas déranger';

  @override
  String get presence_preset_dnd_note => 'Ne pas déranger';

  @override
  String get presence_preset_inTransit_name => 'Déplacement';

  @override
  String get presence_preset_inTransit_note => 'En déplacement';

  @override
  String get presence_preset_meal_name => 'Repas';

  @override
  String get presence_preset_meal_note => 'Au repas';

  @override
  String get presence_preset_meeting_name => 'Réunion';

  @override
  String get presence_preset_meeting_note => 'En réunion';

  @override
  String get presence_preset_sleeping_name => 'Endormi';

  @override
  String get presence_preset_sleeping_note => 'Endormi';

  @override
  String get presence_preset_travel_name => 'Voyage';

  @override
  String get presence_preset_travel_note => 'En voyage';

  @override
  String get presence_preset_unavailable_name => 'Indisponible';

  @override
  String get presence_preset_vacation_name => 'Vacances';

  @override
  String get presence_preset_vacation_note => 'En vacances';

  @override
  String get presence_settings_activity_label => 'Activité';

  @override
  String get presence_settings_activity_tooltip =>
      'Décrit l\'activité actuelle plus en détail. Utilise l\'élément \"activities\" de l\'extension SIP \"RPID\" dans le contenu pidf (voir RFC 4480)';

  @override
  String get presence_settings_availability_title => 'Disponibilité :';

  @override
  String get presence_settings_availability_tooltip =>
      'Représente la disponibilité générale pour les communications au sein du service SIP. Utilise l\'élément \"Status\" de SIP dans le contenu pidf avec les valeurs \"open/closed\" (voir RFC 3863)';

  @override
  String get presence_settings_config_title => 'Configuration :';

  @override
  String get presence_settings_dnd_title => 'Refuser les appels (DND)';

  @override
  String get presence_settings_dnd_tooltip =>
      'Lorsque cette option est activée, tous les appels entrants sont automatiquement refusés par le serveur avec la réponse \"603 Declined\".';

  @override
  String get presence_settings_note_label => 'Note';

  @override
  String get presence_settings_note_tooltip =>
      'Une courte note décrivant en détail le statut actuel. Utilise l\'élément \"note\" de SIP dans le contenu pidf (voir RFC 3863)';

  @override
  String get presence_settings_presets_label => 'Choisir un préréglage';

  @override
  String get presence_settings_presets_label_custom => 'Personnalisé';

  @override
  String get presence_settings_presets_title => 'Préréglages :';

  @override
  String get presence_settings_statusIcon_none => 'Aucune';

  @override
  String get presence_settings_statusIcon_title => 'Icône de statut :';

  @override
  String recents_BodyCenter_empty(Object filter) {
    return 'Vous n\'avez actuellement aucun appel récent $filter.';
  }

  @override
  String get recents_DeleteConfirmDialog_content => 'Voulez-vous vraiment supprimer le journal d\'appels actuel ?';

  @override
  String get recents_DeleteConfirmDialog_title => 'Confirmer la suppression';

  @override
  String get recents_HistoryTile_missedCallText => 'Manqué';

  @override
  String recents_snackBar_deleted(String name) {
    return '$name supprimé';
  }

  @override
  String get recentsVisibilityFilter_all => 'Tous';

  @override
  String get recentsVisibilityFilter_all_preposit => 'tous';

  @override
  String get recentsVisibilityFilter_incoming => 'Entrants';

  @override
  String get recentsVisibilityFilter_incoming_preposit => 'entrants';

  @override
  String get recentsVisibilityFilter_missed => 'Manqués';

  @override
  String get recentsVisibilityFilter_missed_preposit => 'manqués';

  @override
  String get recentsVisibilityFilter_outgoing => 'Sortants';

  @override
  String get recentsVisibilityFilter_outgoing_preposit => 'sortants';

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
  String get request_Id => 'ID de la requête';

  @override
  String get request_StatusCode => 'Code de statut';

  @override
  String get request_StatusName => 'Nom du statut';

  @override
  String get sessionStatus_AppBar_waitingForNetwork => 'En attente de réseau...';

  @override
  String get sessionStatus_AppBar_waitingForConnection => 'En attente de connexion...';

  @override
  String get sessionStatus_AppBar_disconnected => 'Déconnecté';

  @override
  String get sessionStatus_AppBar_connecting => 'Connexion...';

  @override
  String get sessionStatus_AppBar_serviceUnavailable => 'Service temporairement indisponible';

  @override
  String get sessionStatus_pushNotificationServiceProblem =>
      'Problème de configuration du service de notifications push';

  @override
  String get sessionStatus_subtitle_connectivityNone => 'Vérifiez le Wi-Fi ou les données mobiles';

  @override
  String get sessionStatus_subtitle_diagnostic => 'Touchez pour les diagnostics';

  @override
  String get sessionStatus_subtitle_inProgress => 'Connexion au serveur...';

  @override
  String get sessionStatus_subtitle_ready => 'Les appels peuvent atteindre ce compte';

  @override
  String get sessionStatus_subtitle_registrationOff => 'L\'enregistrement est désactivé';

  @override
  String get sessionStatus_subtitle_serviceUnavailable => 'Votre connexion est correcte, touchez pour les détails';

  @override
  String get session_Teardown_progressText => 'Déconnexion en cours...';

  @override
  String get session_Restart_progressText => 'Application des modifications du serveur...';

  @override
  String get session_Restart_loadingText => 'Chargement de vos paramètres depuis le serveur...';

  @override
  String get session_Restart_unreachableText =>
      'Impossible de joindre le serveur pour charger vos paramètres. Vérifiez la connexion et réessayez.';

  @override
  String get session_Restart_retryButton => 'Réessayer';

  @override
  String get session_Restart_logoutButton => 'Se déconnecter';

  @override
  String get sessions_AppBar_title => 'Sessions actives';

  @override
  String get sessions_AppType_android => 'Application Android';

  @override
  String get sessions_AppType_ios => 'Application iOS';

  @override
  String get sessions_AppType_linux => 'Application Linux';

  @override
  String get sessions_AppType_macos => 'Application macOS';

  @override
  String get sessions_AppType_smart => 'Appareil connecté';

  @override
  String get sessions_AppType_unknown => 'Appareil inconnu';

  @override
  String get sessions_AppType_web => 'Application web';

  @override
  String get sessions_AppType_windows => 'Application Windows';

  @override
  String get sessions_AutoTerminate_title => 'Terminer les sessions inactives';

  @override
  String get sessions_AutoTerminate_never => 'Jamais';

  @override
  String get sessions_AutoTerminate_oneWeek => '1 semaine';

  @override
  String get sessions_AutoTerminate_oneMonth => '1 mois';

  @override
  String get sessions_AutoTerminate_threeMonths => '3 mois';

  @override
  String sessions_AutoTerminate_days(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days jours', one: '$days jour');
    return '$_temp0';
  }

  @override
  String sessions_AutoTerminate_default(String period) {
    return 'Par défaut ($period)';
  }

  @override
  String get sessions_AutoTerminate_other => 'Autre…';

  @override
  String sessions_AutoTerminate_adminLimitNote(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days jours', one: '$days jour');
    return 'Les sessions inactives depuis plus de $_temp0 sont terminées automatiquement. Cette limite est définie par votre administrateur.';
  }

  @override
  String sessions_AutoTerminate_info(int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days jours', one: '$days jour');
    return 'Les sessions inactives se terminent après $_temp0';
  }

  @override
  String get sessions_AutoTerminateOther_title => 'Période personnalisée';

  @override
  String get sessions_AutoTerminateOther_label => 'Jours';

  @override
  String sessions_AutoTerminateOther_range(int max) {
    return 'De 1 à $max';
  }

  @override
  String get sessions_AutoTerminateOther_save => 'Enregistrer';

  @override
  String get sessions_Button_retry => 'Réessayer';

  @override
  String get sessions_Button_revokeAllOthers => 'Déconnecter les autres sessions';

  @override
  String get sessions_Placeholder_empty => 'Aucune session active';

  @override
  String get sessions_Placeholder_failure => 'Impossible de charger les sessions actives';

  @override
  String get sessions_RevokeAllConfirmDialog_content =>
      'Les autres appareils connectés avec ce compte seront déconnectés.';

  @override
  String get sessions_RevokeAllConfirmDialog_title => 'Déconnecter les autres sessions ?';

  @override
  String get sessions_RevokeConfirmDialog_content => 'Cet appareil sera déconnecté du compte.';

  @override
  String get sessions_RevokeConfirmDialog_title => 'Déconnecter cette session ?';

  @override
  String get sessions_SnackBar_autoTerminateFailed => 'Impossible de modifier la fin des sessions inactives';

  @override
  String get sessions_SnackBar_autoTerminateLimitChanged =>
      'Votre administrateur a modifié la limite. Choisissez à nouveau la période.';

  @override
  String get sessions_SnackBar_autoTerminateNotSupported =>
      'Le choix de la fin des sessions inactives n\'est plus disponible';

  @override
  String sessions_Section_otherDevices(int count) {
    return 'Autres appareils · $count';
  }

  @override
  String get sessions_SnackBar_revokeFailed => 'Impossible de déconnecter la session';

  @override
  String get sessions_Tile_activeNow => 'Active maintenant';

  @override
  String sessions_Tile_appVersion(String version) {
    return 'Application $version';
  }

  @override
  String get sessions_Tile_currentSession => 'Cet appareil';

  @override
  String get sessions_Tile_revokeTooltip => 'Déconnecter';

  @override
  String get settings_AboutText_ApplicationEmbeddedLinks => 'Liens intégrés à l\'application';

  @override
  String get settings_AboutText_BackendCapabilities => 'Fonctionnalités du backend';

  @override
  String get settings_AboutBackendCapabilities_none => 'Le backend n\'indique aucune fonctionnalité.';

  @override
  String get settings_AboutBackendCapabilities_removedOnServer =>
      'Désactivée sur le serveur - encore utilisée jusqu\'au prochain démarrage de l\'application';

  @override
  String get settings_AboutBackendCapabilities_addedOnServer =>
      'Activée sur le serveur - pas encore utilisée jusqu\'au prochain démarrage de l\'application';

  @override
  String get settings_AboutText_ThirdPartyLicenses => 'Licences tierces';

  @override
  String get settings_AboutText_AppSessionIdentifier => 'Identifiant de session de l\'application';

  @override
  String get settings_AboutText_AppVersion => 'Version de l\'application';

  @override
  String get settings_AboutText_BundleVersion => 'Version du bundle';

  @override
  String get settings_AboutText_CoreVersion => 'Version du core';

  @override
  String get settings_AboutText_CoreVersionUndefined => '?.?.?';

  @override
  String get settings_AboutText_FCMPushNotificationToken => 'Token de notification push FCM';

  @override
  String get settings_AboutText_StoreVersion => 'Version de build dans le Store';

  @override
  String get settings_AccountDeleteConfirmDialog_content => 'Voulez-vous vraiment supprimer le compte ?';

  @override
  String get settings_AccountDeleteConfirmDialog_title => 'Confirmer la suppression du compte';

  @override
  String get settings_AccountDeleteNotSupported_message =>
      'Malheureusement, votre produit ne prend pas en charge la suppression de compte.';

  @override
  String get settings_AppBarTitle_myAccount => 'Mon compte';

  @override
  String get settings_SemanticsLabel_editAccount => 'Modifier les détails du compte';

  @override
  String get settings_audioProcessing_Section_AGC_title => 'Contrôle automatique du gain';

  @override
  String get settings_audioProcessing_Section_AM_title => 'Transfert audio';

  @override
  String get settings_audioProcessing_Section_EC_title => 'Annulation d\'écho';

  @override
  String get settings_audioProcessing_Section_HPF_title => 'Filtre passe-haut';

  @override
  String get settings_audioProcessing_Section_NS_title => 'Suppression du bruit';

  @override
  String get settings_audioProcessing_Section_title => 'Prétraitement audio';

  @override
  String get settings_audioProcessing_Section_tooltip =>
      'Peut être utilisé pour régler la qualité audio selon des besoins ou des environnements spécifiques, comme l\'enregistrement en studio ou un micro externe. \n\nIgnorer le traitement vocal - indique au système de ne pas appliquer le traitement vocal matériel (nécessite un redémarrage de l\'application).';

  @override
  String get settings_audioProcessing_Section_VP_title => 'Ignorer le traitement vocal';

  @override
  String get settings_call_codecs_preferred_audio_default => 'Auto';

  @override
  String get settings_call_codecs_preferred_audio_tip =>
      'Le codec audio préféré est utilisé pour les appels audio. Si le codec n\'est pas pris en charge par l\'appareil, l\'appel sera établi avec le codec disponible suivant.';

  @override
  String get settings_call_codecs_preferred_audio_title => 'Codec audio préféré';

  @override
  String get settings_call_codecs_preferred_video_default => 'Auto';

  @override
  String get settings_call_codecs_preferred_video_tip =>
      'Le codec vidéo préféré est utilisé pour les appels vidéo. Si le codec n\'est pas pris en charge par l\'appareil, l\'appel sera établi avec le codec disponible suivant.';

  @override
  String get settings_call_codecs_preferred_video_title => 'Codec vidéo préféré';

  @override
  String get settings_certificateVerification_Section_title => 'Vérification du certificat TURN';

  @override
  String get settings_certificateVerification_Section_tooltip =>
      'Comment le certificat du serveur relais est vérifié. Ne modifiez ce paramètre que si les appels ne se connectent pas et que le support vous l\'a demandé.';

  @override
  String get settings_certificateVerification_verify => 'Vérifier';

  @override
  String get settings_certificateVerification_disabled => 'Ne pas vérifier';

  @override
  String get settings_certificateVerification_warning =>
      'Sans vérification, la connexion au serveur relais peut être interceptée. L\'audio et la vidéo des appels restent chiffrés dans tous les cas. Réactivez-la une fois le serveur corrigé.';

  @override
  String get settings_speakerOnMinimize_Section_title => 'Haut-parleur en quittant l\'appel';

  @override
  String get settings_speakerOnMinimize_Section_tooltip =>
      'Indique si un appel audio passe en haut-parleur lorsque vous quittez l\'écran d\'appel, et revient à l\'écouteur à votre retour.';

  @override
  String get settings_speakerOnMinimize_switch => 'Activer le haut-parleur en quittant l\'écran d\'appel';

  @override
  String get settings_callerId_cancel_button => 'Annuler';

  @override
  String get settings_callerId_defaultTitle => 'ID appelant par défaut';

  @override
  String get settings_callerId_dialcode => 'Indicatif :';

  @override
  String get settings_callerId_dialCodeMatching_title => 'Correspondance des indicatifs';

  @override
  String get settings_callerId_duplicate_dialcode_error =>
      'Veuillez choisir un autre indicatif, celui-ci est déjà utilisé.';

  @override
  String get settings_callerId_number => 'Numéro :';

  @override
  String get settings_callerId_number_hint => 'Sélectionnez un numéro';

  @override
  String get settings_callerId_save_button => 'Enregistrer';

  @override
  String get settings_connectionSection_title => 'Connexion et comportement des appels';

  @override
  String get settings_connectionSection_tooltip =>
      'Configurez la manière dont votre appareil gère l\'établissement de la connexion, la négociation des médias et les mises à jour des appels lors des communications pair-à-pair.';

  @override
  String get settings_encoding_AppBar_reset_tooltip => 'Réinitialiser';

  @override
  String get settings_encoding_Section_audio_ptime => 'ptime audio cible : ';

  @override
  String get settings_encoding_Section_audio_ptime_limit => 'Limite du ptime audio : ';

  @override
  String get settings_encoding_Section_bandwidth_prefix => 'Fréquence d\'échantillonnage : ';

  @override
  String get settings_encoding_Section_bitrate_prefix => 'Débit binaire : ';

  @override
  String get settings_encoding_Section_bitrate_title => 'Paramètres du débit binaire des codecs';

  @override
  String get settings_encoding_Section_bitrate_tooltip =>
      'Ajustez les paramètres du débit binaire pour les codecs audio et vidéo : des valeurs plus faibles réduisent l\'utilisation de la bande passante mais affectent la qualité, des valeurs plus élevées améliorent la qualité mais augmentent aussi l\'utilisation de la bande passante.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeREMBFeedback => 'Supprimer le feedback REMB';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeREMBFeedback_tooltip =>
      'Supprime les lignes de feedback RTCP goog-remb du SDP. Désactive l\'estimation de la bande passante côté récepteur sur certains terminaux.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeTWCCFeedback => 'Supprimer le feedback TWCC';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeTWCCFeedback_tooltip =>
      'Supprime le feedback RTCP transport-cc et l\'extmap transport-wide-cc du SDP. Désactive le contrôle de congestion étendu au transport.';

  @override
  String get settings_encoding_Section_rtp_extensions_title => 'Extensions RTP';

  @override
  String get settings_encoding_Section_rtp_extensions_tooltip =>
      'Désactive les extensions d\'en-tête RTP individuelles lors de la négociation SDP.';

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
  String get settings_encoding_Section_extra_sdp_mod_remapTE8 => 'Convertir le code TE_8k en 101';

  @override
  String get settings_encoding_Section_extra_sdp_mod_remapTE8_tooltip =>
      'Change le type de charge utile TE8 en 101 dans le SDP pour une meilleure compatibilité avec certains terminaux SIP.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeStaticRtpmaps => 'Supprimer les lignes rtpmap statiques';

  @override
  String get settings_encoding_Section_extra_sdp_mod_removeStaticRtpmaps_tooltip =>
      'Supprime du SDP les lignes de mappage RTP statiques des codecs audio (par ex. PCMU, PCMA) afin de réduire la taille du SDP. Peut aider avec les problèmes de fragmentation MTU sur certains terminaux SIP.';

  @override
  String get settings_encoding_Section_extra_sdp_mod_title => 'Modifications SDP supplémentaires';

  @override
  String get settings_encoding_Section_measure_hz => 'Hz';

  @override
  String get settings_encoding_Section_measure_kbps => 'Kbps';

  @override
  String get settings_encoding_Section_measure_ms => 'ms';

  @override
  String get settings_encoding_Section_opus_bandwidth => 'Forcer la bande passante : ';

  @override
  String get settings_encoding_Section_opus_bitrate => 'Forcer le débit : ';

  @override
  String get settings_encoding_Section_opus_channels => 'Forcer le mode canaux : ';

  @override
  String get settings_encoding_Section_opus_dtx => 'Forcer le mode DTX : ';

  @override
  String get settings_encoding_Section_opus_samplingRate => 'Forcer la fréquence d\'échantillonnage : ';

  @override
  String get settings_encoding_Section_opus_title => 'Réglage du codec Opus';

  @override
  String get settings_encoding_Section_opus_tooltip =>
      'Ajuste les paramètres spécifiques du codec Opus. Permet de réduire l\'usage de la bande passante ou d\'améliorer la qualité audio';

  @override
  String get settings_encoding_Section_packetization_title => 'Paquetisation audio';

  @override
  String get settings_encoding_Section_packetization_tooltip =>
      'Ajuste la durée de paquetisation audio en millisecondes, permet de réduire la latence audio ou de résoudre les problèmes de taille MTU du réseau';

  @override
  String get settings_encoding_Section_packetization_warning_title => 'Attention :';

  @override
  String get settings_encoding_Section_packetization_warning_message =>
      'Certains codecs peuvent Peine avec des valeurs ptime non standard, provoquant des coupures ou un silence audibles. À n\'utiliser que si vous savez ce que vous faites.';

  @override
  String get settings_encoding_Section_preset => 'Préréglage';

  @override
  String get settings_encoding_Section_preset_balance => 'Équilibré';

  @override
  String get settings_encoding_Section_preset_balance_tooltip =>
      'Équilibre la qualité des appels et l\'usage des données.';

  @override
  String get settings_encoding_Section_preset_eco => 'Bande passante réduite';

  @override
  String get settings_encoding_Section_preset_eco_tooltip =>
      'Utilise moins de données Internet et fonctionne mieux sur des connexions lentes ou instables.';

  @override
  String get settings_encoding_Section_preset_custom => 'Personnalisé';

  @override
  String get settings_encoding_Section_preset_custom_tooltip =>
      'Ajustez manuellement les paramètres de qualité des appels.';

  @override
  String get settings_encoding_Section_preset_default => 'Recommandé';

  @override
  String get settings_encoding_Section_preset_default_tooltip =>
      'Les paramètres par défaut de qualité média choisis pour cette application. Convient à la plupart des appels';

  @override
  String get settings_encoding_Section_preset_bypass => 'Mode compatibilité';

  @override
  String get settings_encoding_Section_preset_bypass_tooltip =>
      'N\'applique pas les paramètres de qualité média et utilise une configuration d\'appel non modifiée. Aide à résoudre les problèmes de compatibilité.';

  @override
  String get settings_encoding_Section_preset_full_flex => 'Pleine qualité';

  @override
  String get settings_encoding_Section_preset_quality => 'Meilleure qualité';

  @override
  String get settings_encoding_Section_preset_quality_tooltip =>
      'Offre la meilleure qualité audio et vidéo. Nécessite une connexion Internet rapide et stable.';

  @override
  String get settings_encoding_Section_preset_title => 'Configurations d\'encodage média';

  @override
  String get settings_encoding_Section_preset_tooltip =>
      'Préréglages pour les codecs audio et vidéo : les valeurs basses réduisent l\'usage de la bande passante mais dégradent la qualité, les valeurs hautes améliorent la qualité mais augmentent aussi l\'usage de la bande passante. Le préréglage par défaut correspond aux réglages recommandés par votre fournisseur selon les préférences de son environnement.';

  @override
  String get settings_encoding_Section_ptime_prefix => 'Ptime : ';

  @override
  String get settings_encoding_Section_rtp_override_audio => 'Forcer les profils audio';

  @override
  String get settings_encoding_Section_rtp_override_conference => 'Forcer les profils audio de conférence';

  @override
  String get settings_encoding_Section_rtp_override_title => 'Activer/désactiver et réordonner les profils RTP';

  @override
  String get settings_encoding_Section_rtp_override_tooltip =>
      'Permet de forcer l\'ordre de priorité des profils RTP audio et vidéo ou d\'exclure certains profils de la liste de négociation SDP. Peut forcer l\'usage de codecs spécifiques ou exclure des codecs mal pris en charge par l\'appareil, le réseau ou le système distant';

  @override
  String get settings_encoding_Section_rtp_override_video => 'Forcer les profils vidéo';

  @override
  String get settings_encoding_Section_rtp_override_warning_message =>
      'Forcer peut nuire à la compatibilité avec d\'autres appareils ou systèmes média et provoquer des erreurs d\'appel, à n\'utiliser que si vous savez ce que vous faites.';

  @override
  String get settings_encoding_Section_rtp_override_warning_title => 'Attention :';

  @override
  String get settings_encoding_Section_target_audio_bitrate => 'Débit audio cible : ';

  @override
  String get settings_encoding_Section_target_video_bitrate => 'Débit vidéo cible : ';

  @override
  String get settings_encoding_Section_value_auto => 'Auto';

  @override
  String get settings_encoding_Section_value_disable => 'Désactiver';

  @override
  String get settings_encoding_Section_value_enable => 'Activer';

  @override
  String get settings_encoding_Section_value_mono => 'Mono';

  @override
  String get settings_encoding_Section_value_off => 'Désactivé';

  @override
  String get settings_encoding_Section_value_on => 'Activé';

  @override
  String get settings_encoding_Section_value_stereo => 'Stéréo';

  @override
  String get settings_iceSettings_Section_netfilter_skipv4 => 'Ignorer les candidats IPv4';

  @override
  String get settings_iceSettings_Section_netfilter_skipv6 => 'Ignorer les candidats IPv6';

  @override
  String get settings_iceSettings_Section_netfilter_title => 'Protocole réseau';

  @override
  String get settings_iceSettings_Section_noskip => 'Aucun filtre';

  @override
  String get settings_iceSettings_Section_title => 'Filtrage des candidats ICE';

  @override
  String get settings_iceSettings_Section_tooltip =>
      'Filtrer les candidats ICE selon les préférences réseau peut aider à éviter les problèmes de réseau';

  @override
  String get settings_iceSettings_Section_trfilter_skipTcp => 'Ignorer les candidats TCP';

  @override
  String get settings_iceSettings_Section_trfilter_skipUdp => 'Ignorer les candidats UDP';

  @override
  String get settings_iceSettings_Section_trfilter_title => 'Protocole de transport';

  @override
  String get settings_ListViewTileSubtitle_registeredNeedsConnection => 'Connexion nécessaire';

  @override
  String get settings_ListViewTileSubtitle_registeredOff => 'Les appels entrants sont refusés';

  @override
  String get settings_ListViewTileSubtitle_registeredOn => 'Le compte peut recevoir des appels';

  @override
  String get settings_ListViewTileSubtitle_registeredUpdating => 'Mise à jour...';

  @override
  String get settings_ListViewTileSubtitle_registeredWaitingForConnection => 'En attente de connexion...';

  @override
  String get settings_ListViewTileTitle_about => 'À propos';

  @override
  String get settings_ListViewTileTitle_accountDelete => 'Supprimer le compte';

  @override
  String get settings_ListViewTileTitle_call_codecs => 'Codecs d\'appel';

  @override
  String get settings_ListViewTileTitle_cacheManagement => 'Stockage et cache';

  @override
  String get settings_ListViewTileTitle_callerId => 'Identifiant de l\'appelant';

  @override
  String get settings_ListViewTileTitle_encoding => 'Encodage média';

  @override
  String get settings_ListViewTileTitle_features => 'SERVICES';

  @override
  String get settings_ListViewTileTitle_help => 'Aide';

  @override
  String get settings_ListViewTileTitle_language => 'Langue';

  @override
  String get settings_ListViewTileTitle_logout => 'Se déconnecter';

  @override
  String get settings_ListViewTileTitle_logRecordsConsole => 'Console des journaux';

  @override
  String get settings_ListViewTileTitle_mediaSettings => 'Paramètres média';

  @override
  String get settings_ListViewTileTitle_network => 'Paramètres réseau';

  @override
  String get settings_ListViewTileTitle_presence => 'Présence SIP';

  @override
  String get settings_ListViewTileTitle_registered => 'En ligne';

  @override
  String get settings_ListViewTileTitle_self_config => 'Page d\'autoconfiguration';

  @override
  String get settings_ListViewTileTitle_callCenter => 'Centre d\'appels';

  @override
  String get settings_ListViewTileTitle_sessions => 'Sessions';

  @override
  String get settings_ListViewTileTitle_settings => 'PARAMÈTRES';

  @override
  String get settings_ListViewTileTitle_termsConditions => 'Conditions générales';

  @override
  String get settings_ListViewTileTitle_themeMode => 'Mode de thème';

  @override
  String get settings_ListViewTileTitle_toolbox => 'OUTILS';

  @override
  String get settings_ListViewTileTitle_voicemail => 'Messagerie vocale';

  @override
  String get settings_LogoutConfirmDialog_content => 'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get settings_LogoutConfirmDialog_title => 'Confirmer la déconnexion';

  @override
  String get settings_missingMicrophoneIndicator_title =>
      'Autorisation du microphone manquante. Impossible de passer des appels.';

  @override
  String get settings_network_fallbackCalls_description =>
      'Si les notifications push d\'appels ne sont pas reçues, l\'application recevra un SMS spécial et affichera l\'écran d\'appel entrant.';

  @override
  String get settings_network_fallbackCalls_title => 'Appels entrants de secours';

  @override
  String get settings_network_incomingCallType_pushNotification_description =>
      'Lorsque l\'application n\'est pas utilisée, elle cesse de fonctionner et consomme peu de ressources, ce qui préserve la batterie. Lors d\'un appel entrant, le serveur envoie une notification push au téléphone, demandant au système d\'exploitation mobile de lancer l\'application pour gérer l\'appel. Toutefois, cette méthode ne garantit pas que tous les appels seront reçus. Si le téléphone est resté inactif longtemps, certaines versions d\'Android peuvent limiter les notifications push, ce qui risque de vous faire manquer un appel entrant.';

  @override
  String get settings_network_incomingCallType_pushNotification_title => 'Notification push';

  @override
  String get settings_network_incomingCallType_socket_description =>
      'L\'application continue de fonctionner en arrière-plan et maintient toujours une connexion active au serveur. Cela augmente les chances de recevoir un appel entrant, mais peut vider la batterie plus rapidement.';

  @override
  String get settings_network_incomingCallType_socket_title => 'Connexion permanente au serveur';

  @override
  String get settings_network_incomingCallType_title => 'Réception des appels entrants';

  @override
  String get settings_network_smsFallback_toggle => 'SMS comme canal de secours';

  @override
  String get settings_registerStatusSnackBar_requestFailed => 'Serveur inaccessible - réessayez';

  @override
  String get settings_registerStatusSnackBar_unavailable =>
      'Aucune connexion au serveur - ce paramètre ne peut pas être modifié maintenant';

  @override
  String get settings_videoCapturing_Section_framerate_prefix => 'images/s : ';

  @override
  String get settings_videoCapturing_Section_framerate_title => 'Fréquence d\'images';

  @override
  String get settings_videoCapturing_Section_resolution_prefix => 'points verticaux : ';

  @override
  String get settings_videoCapturing_Section_resolution_title => 'Résolution de l\'image';

  @override
  String get settings_videoCapturing_Section_title => 'Capture vidéo';

  @override
  String get settings_videoCapturing_Section_tooltip =>
      'Permet d\'adapter la qualité vidéo à des besoins ou environnements spécifiques.';

  @override
  String get settings_videoOffer_option_ignore =>
      'Répondre sans vidéo\nAucune piste ne sera ajoutée sauf négociation ultérieure.';

  @override
  String get settings_videoOffer_option_includeInactive =>
      'Inclure la piste vidéo inactive\nGarantit la compatibilité avec les offres vidéo pour une activation future.';

  @override
  String get settings_videoOffer_title => 'Détermine comment cet appareil répond à une offre incluant la vidéo.';

  @override
  String get signalingResponseCode_ambiguousRequest => 'Nous n\'avons pas compris votre demande.';

  @override
  String get signalingResponseCode_busyEverywhere =>
      'L\'utilisateur que vous tentez de joindre est occupé. Réessayez plus tard.';

  @override
  String get signalingResponseCode_callNotExist => 'La demande ne correspond à aucun dialogue ni transaction.\n';

  @override
  String get signalingResponseCode_declineCall => 'L\'appel a été refusé.';

  @override
  String get signalingResponseCode_errorAttachingPlugin =>
      'Nous avons eu du mal à connecter une fonctionnalité. Réessayez plus tard.';

  @override
  String get signalingResponseCode_errorDetachingPlugin =>
      'Nous avons eu du mal à déconnecter une fonctionnalité. Réessayez plus tard.';

  @override
  String get signalingResponseCode_errorSendingMessage =>
      'Nous n\'avons pas pu envoyer votre message. Vérifiez votre réseau et réessayez.';

  @override
  String get signalingResponseCode_exchangeRoutingError =>
      'Nous n\'avons pas trouvé de route pour effectuer votre demande. Réessayez plus tard.';

  @override
  String get signalingResponseCode_handleNotFound => 'Nous n\'avons pas trouvé ce que vous cherchiez. Réessayez.';

  @override
  String get signalingResponseCode_incompatibleDestination =>
      'Le destinataire que vous tentez de joindre est incompatible.';

  @override
  String get signalingResponseCode_invalidElementType => 'Quelque chose ne va pas. Réessayez.';

  @override
  String get signalingResponseCode_invalidJson =>
      'Une erreur est survenue lors du traitement de vos données. Réessayez.';

  @override
  String get signalingResponseCode_invalidJsonObject =>
      'Certaines informations fournies n\'étaient pas valides. Vérifiez et réessayez.';

  @override
  String get signalingResponseCode_invalidNumberFormat => 'Format de numéro invalide';

  @override
  String get signalingResponseCode_invalidPath => 'L\'action demandée n\'est pas disponible. Essayez une autre option.';

  @override
  String get signalingResponseCode_invalidSdp => 'Une erreur technique est survenue. Réessayez plus tard.';

  @override
  String get signalingResponseCode_invalidStream => 'Le flux demandé n\'est pas disponible. Réessayez.';

  @override
  String get signalingResponseCode_loopDetected => 'Nous avons détecté une boucle dans l\'appel. Réessayez.';

  @override
  String get signalingResponseCode_missingMandatoryElement =>
      'Des informations obligatoires sont manquantes. Remplissez tous les champs requis.';

  @override
  String get signalingResponseCode_missingRequest => 'Un problème est survenu avec votre demande. Réessayez.';

  @override
  String get signalingResponseCode_normalUnspecified => 'Une erreur est survenue. Réessayez plus tard.';

  @override
  String get signalingResponseCode_notAcceptable =>
      'L\'appel a été marqué comme non acceptable. Vérifiez vos routes sortantes !';

  @override
  String get signalingResponseCode_notAcceptingNewSessions =>
      'Nous ne pouvons pas démarrer de nouvelles sessions pour le moment. Réessayez plus tard.';

  @override
  String get signalingResponseCode_notFoundRoutesInReplyFromBE =>
      'Nous n\'avons pas trouvé de route pour effectuer votre demande. Réessayez plus tard.';

  @override
  String get signalingResponseCode_pluginNotFound =>
      'Un composant requis est manquant. Essayez de redémarrer l\'application.';

  @override
  String get signalingResponseCode_rejected => 'Appel refusé';

  @override
  String get signalingResponseCode_requestTerminated => 'Votre demande a été interrompue. Réessayez.';

  @override
  String get signalingResponseCode_sessionIdInUse => 'Cette session est déjà active. Essayez d\'en utiliser une autre.';

  @override
  String get signalingResponseCode_sessionNotFound => 'Votre session est introuvable. Connectez-vous et réessayez.';

  @override
  String get signalingResponseCode_tokenNotFound =>
      'Votre jeton d\'accès est manquant ou invalide. Connectez-vous à nouveau.';

  @override
  String get signalingResponseCode_transportSpecificError =>
      'Un problème de connexion est survenu. Vérifiez votre réseau et réessayez.';

  @override
  String get signalingResponseCodeType_callHangup => 'L\'appel a été terminé.';

  @override
  String get signalingResponseCodeType_plugin =>
      'Une fonctionnalité requise ne fonctionne pas correctement. Essayez de redémarrer l\'application.';

  @override
  String get signalingResponseCodeType_request => 'Un problème est survenu avec votre demande. Réessayez.';

  @override
  String get signalingResponseCodeType_session =>
      'Un problème est survenu avec votre session. Reconnectez-vous ou redémarrez l\'application.';

  @override
  String get signalingResponseCodeType_token => 'Votre jeton d\'accès n\'est pas valide. Connectez-vous à nouveau.';

  @override
  String get signalingResponseCodeType_transport =>
      'Nous avons du mal à communiquer avec le serveur. Vérifiez votre connexion et réessayez.';

  @override
  String get signalingResponseCodeType_unauthorized =>
      'Vous n\'avez pas l\'autorisation nécessaire. Connectez-vous ou contactez le support.';

  @override
  String get signalingResponseCodeType_unknown => 'Un problème inattendu est survenu. Réessayez plus tard.';

  @override
  String get signalingResponseCodeType_webrtc =>
      'Un problème est survenu avec la connexion de l\'appel. Raccrochez et réessayez.';

  @override
  String get signalingResponseCode_unauthorizedAccess =>
      'Vous n\'avez pas l\'autorisation d\'accéder à cette fonctionnalité. Contactez le support si vous pensez qu\'il s\'agit d\'une erreur.';

  @override
  String get signalingResponseCode_unauthorizedRequest =>
      'Votre demande n\'a pas pu être autorisée. Essayez de vous connecter à nouveau.';

  @override
  String get signalingResponseCode_unexpectedAnswer => 'Nous avons reçu une réponse inattendue. Réessayez.';

  @override
  String get signalingResponseCode_unknownError => 'Une erreur inattendue est survenue. Réessayez plus tard.';

  @override
  String get signalingResponseCode_unknownRequest =>
      'Nous n\'avons pas reconnu cette demande. Réessayez ou contactez le support.';

  @override
  String get signalingResponseCode_unsupportedJsepType =>
      'Cette action n\'est pas prise en charge par votre configuration actuelle.';

  @override
  String get signalingResponseCode_unwanted => 'Le destinataire a marqué l\'appel comme indésirable.';

  @override
  String get signalingResponseCode_userBusy => 'Utilisateur occupé';

  @override
  String get signalingResponseCode_userNotExist => 'L\'utilisateur n\'existe pas';

  @override
  String get signalingResponseCode_unableToComplete => 'Impossible de passer l\'appel.';

  @override
  String get signalingResponseCode_wrongWebrtcState =>
      'Une erreur liée à l\'appel est survenue. Raccrochez et réessayez.';

  @override
  String get socketError_connectionRefused => 'Connexion refusée';

  @override
  String get socketError_connectionRefusedDescription =>
      'Le serveur a refusé la connexion. Le serveur est peut-être arrêté ou refuse les requêtes. Réessayez plus tard.';

  @override
  String get socketError_connectionReset => 'Connexion réinitialisée';

  @override
  String get socketError_connectionResetDescription => 'La connexion a été réinitialisée par le serveur. Réessayez.';

  @override
  String get socketError_connectionTimedOut => 'Délai de connexion dépassé';

  @override
  String get socketError_connectionTimedOutDescription =>
      'Le délai de connexion est dépassé. Cela peut arriver avec une connexion Internet lente ou instable. Vérifiez votre connexion et réessayez.';

  @override
  String get socketError_default => 'Erreur réseau';

  @override
  String socketError_defaultDescription(int? errorCode) {
    return 'Une erreur réseau inattendue est survenue (code d\'erreur : $errorCode). Elle peut être due à des problèmes réseau ou au serveur. Réessayez plus tard.';
  }

  @override
  String get socketError_networkUnreachable => 'Réseau inaccessible';

  @override
  String get socketError_networkUnreachableDescription =>
      'Le réseau est inaccessible. Cela peut être dû à une connexion Internet faible, à des restrictions réseau comme les pare-feu ou à des réglages DNS erronés. Sur un réseau d\'entreprise ou restreint, contactez votre administrateur réseau ou essayez un autre réseau.';

  @override
  String get socketError_serverUnreachable => 'Le serveur est inaccessible en raison de problèmes réseau';

  @override
  String get socketError_serverUnreachableDescription =>
      'Le serveur est inaccessible. Cela peut être dû à l\'absence de connexion Internet ou à une maintenance du serveur. Vérifiez votre connexion Internet et réessayez.';

  @override
  String get system_notifications_screen_list_empty => 'Aucune notification pour le moment';

  @override
  String get system_notifications_screen_title => 'Notifications';

  @override
  String get system_notifications_Dialog_deleteAllContent =>
      'Elles seront supprimées de votre compte, pas seulement de cet appareil. Cette action est irréversible.';

  @override
  String system_notifications_Dialog_deleteAllTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count notifications ?',
      one: 'Supprimer $count notification ?',
    );
    return '$_temp0';
  }

  @override
  String get system_notifications_SemanticsAction_delete => 'Supprimer';

  @override
  String get system_notifications_SemanticsLabel_deleteAll => 'Supprimer toutes les notifications';

  @override
  String get themeMode_dark => 'Sombre';

  @override
  String get themeMode_light => 'Clair';

  @override
  String get themeMode_system => 'Système';

  @override
  String get undefined_autoprovision_invalidToken =>
      'Les identifiants d\'autoconfiguration ont été refusés par le serveur. Demandez un nouveau lien de configuration';

  @override
  String get undefined_autoprovision_invalidToken_title => 'Configuration invalide';

  @override
  String get undefined_stackScreenNotSupported => 'Fonctionnalité non prise en charge. Contactez l\'administrateur.';

  @override
  String get undefined_stackScreenNotSupported_title => 'Fonctionnalité non prise en charge';

  @override
  String get user_agreement_agrement_link => 'Les conditions générales de l\'accord';

  @override
  String get user_agreement_button_text => 'Continuer';

  @override
  String user_agreement_checkbox_text(Object url) {
    return 'J\'ai lu $url et j\'accepte ses conditions.';
  }

  @override
  String user_agreement_description(Object appName) {
    return 'Bienvenue dans $appName';
  }

  @override
  String get validationBlankError => 'Veuillez saisir une valeur';

  @override
  String get voicemail_Cache_description =>
      'L\'écoute d\'un message vocal conserve une copie locale de l\'audio pour une réécriture immédiate. Vider le cache libère de l\'espace ; l\'audio est téléchargé à nouveau à la prochaine lecture.';

  @override
  String get voicemail_Cache_title => 'Audio des messages vocaux';

  @override
  String get voicemail_Description_notSupported =>
      'La messagerie vocale n\'est pas prise en charge par votre cœur. Contactez votre administrateur pour plus d\'informations.';

  @override
  String get voicemail_Dialog_deletePermanentlyContent =>
      'Ce message sera supprimé de votre boîte aux lettres et ne pourra pas être restauré.';

  @override
  String get voicemail_Dialog_deletePermanentlyTitle => 'Supprimer définitivement ?';

  @override
  String get voicemail_Dialog_deleteSelectedContent =>
      'Les messages vocaux sélectionnés seront définitivement supprimés. Voulez-vous continuer ?';

  @override
  String get voicemail_Dialog_deleteSelectedPermanentlyContent =>
      'Les messages sélectionnés seront supprimés de votre boîte aux lettres et ne pourront pas être restaurés.';

  @override
  String voicemail_Dialog_deleteSelectedPermanentlyTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer définitivement $count messages ?',
      one: 'Supprimer définitivement le message ?',
      zero: 'Supprimer définitivement $count messages ?',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Dialog_deleteSelectedTitle => 'Supprimer les messages vocaux sélectionnés ?';

  @override
  String get voicemail_Dialog_deleteSingleContent =>
      'Ce message vocal sera définitivement supprimé. Voulez-vous continuer ?';

  @override
  String get voicemail_Dialog_deleteSingleTitle => 'Supprimer le message vocal ?';

  @override
  String get voicemail_Filter_all => 'Tous';

  @override
  String get voicemail_Filter_saved => 'Enregistrés';

  @override
  String get voicemail_Filter_trash => 'Corbeille';

  @override
  String get voicemail_Filter_unheard => 'Nouveaux';

  @override
  String voicemail_Dialog_emptyTrashContent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les $count messages de la corbeille seront supprimés et l\'espace qu\'ils occupent sera libéré.',
      one: 'Le message de la corbeille sera supprimé et l\'espace qu\'il occupe sera libéré.',
      zero: 'Les $count messages de la corbeille seront supprimés et l\'espace qu\'ils occupent sera libéré.',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Dialog_emptyTrashTitle => 'Vider la corbeille ?';

  @override
  String get voicemail_Label_call => 'Appeler';

  @override
  String get voicemail_Label_delete => 'Supprimer';

  @override
  String get voicemail_Label_deleteAll => 'Supprimer tous les messages vocaux ?';

  @override
  String get voicemail_Label_deleteAllDescription =>
      'Cette action supprimera définitivement tous vos messages vocaux. Elle est irréversible.';

  @override
  String get voicemail_Label_deletePermanently => 'Supprimer définitivement';

  @override
  String get voicemail_Label_empty => 'Aucun message vocal';

  @override
  String get voicemail_Label_emptySaved => 'Aucun message enregistré';

  @override
  String get voicemail_Label_emptySavedHint =>
      'Ouvrez le menu d\'un message et choisissez Enregistrer pour le garder ici.';

  @override
  String get voicemail_Label_emptyTrash => 'La corbeille est vide';

  @override
  String get voicemail_Label_emptyTrashAction => 'Vider la corbeille';

  @override
  String get voicemail_Label_emptyTrashHint =>
      'Les messages que vous y placez occupent encore de la place dans la boîte aux lettres tant que la corbeille n\'est pas vidée.';

  @override
  String get voicemail_Label_forward => 'Transférer';

  @override
  String get voicemail_Label_forwardAgain => 'Transférer à nouveau';

  @override
  String get voicemail_Label_forwardChoosing => 'Choisissez le destinataire';

  @override
  String voicemail_Label_forwardedBy(String name) {
    return 'Transféré par $name';
  }

  @override
  String get voicemail_Label_markAsHeard => 'Marquer comme écouté';

  @override
  String get voicemail_Label_markAsNew => 'Marquer comme nouveau';

  @override
  String get voicemail_Label_moveToTrash => 'Mettre à la corbeille';

  @override
  String voicemail_Label_notForwarded(String name) {
    return 'Non transféré · $name';
  }

  @override
  String get voicemail_Label_openContact => 'Ouvrir le contact';

  @override
  String get voicemail_Label_playbackError => 'Échec de la lecture';

  @override
  String get voicemail_Label_restore => 'Restaurer';

  @override
  String get voicemail_Label_restoreSelected => 'Restaurer la sélection';

  @override
  String get voicemail_Label_retry => 'Réessayer';

  @override
  String get voicemail_Label_save => 'Enregistrer';

  @override
  String get voicemail_Label_trashFootnote =>
      'Les messages de la corbeille occupent encore de la place dans la boîte aux lettres tant qu\'elle n\'est pas vidée.';

  @override
  String get voicemail_Label_undo => 'Annuler';

  @override
  String voicemail_Label_unheardCount(int count) {
    return '$count nouveau(x)';
  }

  @override
  String get voicemail_Label_unsave => 'Ne plus enregistrer';

  @override
  String voicemail_SemanticsLabel_filter(String filter) {
    return 'Filtre, actuellement $filter';
  }

  @override
  String common_SemanticsValue_durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds secondes',
      one: '$seconds seconde',
    );
    return '$_temp0';
  }

  @override
  String common_SemanticsValue_durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0';
  }

  @override
  String common_SemanticsValue_durationMinutesSeconds(String minutes, String seconds) {
    return '$minutes $seconds';
  }

  @override
  String voicemail_SemanticsValue_playbackPosition(String position, String duration) {
    return '$position sur $duration';
  }

  @override
  String voicemail_SemanticsLabel_forwardTo(String name) {
    return 'Transférer à $name';
  }

  @override
  String voicemail_SemanticsAnnouncement_selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages sélectionnés',
      one: '$count message sélectionné',
      zero: 'Aucun message sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_SemanticsLabel_forwarding => 'Transfert en cours';

  @override
  String get voicemail_SemanticsLabel_loading => 'Chargement';

  @override
  String get voicemail_SemanticsLabel_moreActions => 'Plus';

  @override
  String get voicemail_SemanticsLabel_pause => 'Pause';

  @override
  String get voicemail_SemanticsLabel_play => 'Lecture';

  @override
  String get voicemail_SemanticsLabel_saved => 'Enregistré';

  @override
  String get voicemail_SemanticsLabel_undoMoveToTrash => 'Annuler la mise à la corbeille';

  @override
  String voicemail_Snackbar_deleteFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les messages n\'ont pas pu être supprimés',
      one: 'Le message n\'a pas pu être supprimé',
      zero: 'Les messages n\'ont pas pu être supprimés',
    );
    return '$_temp0';
  }

  @override
  String voicemail_Snackbar_restoreFailed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Les messages n\'ont pas pu être restaurés',
      one: 'Le message n\'a pas pu être restauré',
      zero: 'Les messages n\'ont pas pu être restaurés',
    );
    return '$_temp0';
  }

  @override
  String get voicemail_Snackbar_updateFailed => 'Le message n\'a pas pu être mis à jour';

  @override
  String get voicemail_Snackbar_emptyTrashFailed => 'La corbeille n\'a pas pu être vidée';

  @override
  String get voicemail_Snackbar_refreshFailed => 'La liste n\'a pas pu être actualisée';

  @override
  String get voicemail_Snackbar_messageGone => 'Ce message n\'existe plus';

  @override
  String get voicemail_Snackbar_movedToTrash => 'Mis à la corbeille';

  @override
  String voicemail_Snackbar_forwardFailed(String name) {
    return 'Impossible de transférer à $name';
  }

  @override
  String voicemail_Snackbar_forwardRecipientFull(String name) {
    return '$name ne peut plus recevoir de messages transférés';
  }

  @override
  String get voicemail_Snackbar_forwardTooLarge => 'Message trop volumineux pour être transféré';

  @override
  String get voicemail_Snackbar_forwardUnavailable => 'Le transfert n\'est pas disponible';

  @override
  String voicemail_Snackbar_forwarded(String name) {
    return 'Transféré à $name';
  }

  @override
  String get voicemail_Snackbar_contactGone => 'Ce contact n\'est plus dans votre carnet d\'adresses';

  @override
  String get voicemail_Snackbar_notConfigured => 'Contactez votre administrateur pour activer la messagerie vocale';

  @override
  String get voicemail_Title_notSupported => 'Fonctionnalité non prise en charge';

  @override
  String get voicemail_Widget_screenTitle => 'Messagerie vocale';

  @override
  String get webRegistration_ErrorAcknowledgeDialogActions_retry => 'Réessayer';

  @override
  String get webRegistration_ErrorAcknowledgeDialogActions_skip => 'Passer';

  @override
  String get webRegistration_ErrorAcknowledgeDialog_title => 'Erreur de ressource web';

  @override
  String webview_defaultError_details(String description, int code) {
    return '$description (code : $code)';
  }

  @override
  String get webview_defaultError_reload => 'Recharger';

  @override
  String get webview_defaultError_title => 'Quelque chose s\'est mal passé';

  @override
  String get webview_sslError_details => 'Détails';

  @override
  String get webview_sslError_details_type => 'Type';

  @override
  String get webview_sslError_details_url => 'URL';

  @override
  String get webview_sslError_message =>
      'Le certificat de ce site n\'est pas approuvé. La page ne peut pas être affichée.';

  @override
  String get webview_sslError_title => 'Votre connexion n\'est pas privée';

  @override
  String get webview_sslError_tryAgain => 'Réessayer';

  @override
  String get cdr_disconnectReason_unknown => 'Inconnu';

  @override
  String get cdr_disconnectReason_validCauseCodeNotYetReceived => 'Code de cause valide pas encore reçu';

  @override
  String get cdr_disconnectReason_unallocatedNumber => 'Numéro non attribué (non assigné)';

  @override
  String get cdr_disconnectReason_noRouteToSpecifiedTransitNetworkWan =>
      'Aucune route vers le réseau de transit spécifié (WAN)';

  @override
  String get cdr_disconnectReason_noRouteToDestination => 'Aucune route vers la destination';

  @override
  String get cdr_disconnectReason_sendSpecialInformationTone => 'envoi de tonalité d\'information spéciale';

  @override
  String get cdr_disconnectReason_misdialledTrunkPrefix => 'préfixe de trunk mal composé.';

  @override
  String get cdr_disconnectReason_channelUnacceptable => 'Canal non acceptable';

  @override
  String get cdr_disconnectReason_callAwardedAndBeingDeliveredInAnEstablishedChannel =>
      'Appel attribué et en cours de livraison sur un canal établi';

  @override
  String get cdr_disconnectReason_prefix0DialedButNotAllowedPreemption =>
      'Préfixe 0 composé mais non autorisé (préemption)';

  @override
  String get cdr_disconnectReason_prefix1DialedButNotAllowedPreemptionReserved =>
      'Préfixe 1 composé mais non autorisé (préemption réservée)';

  @override
  String get cdr_disconnectReason_prefix1DialedButNotRequired => 'Préfixe 1 composé mais non requis';

  @override
  String get cdr_disconnectReason_moreDigitsReceivedThanAllowedCallIsProceeding =>
      'Plus de chiffres reçus qu\'autorisés, l\'appel continue';

  @override
  String get cdr_disconnectReason_normalCallClearing => 'Libération normale de l\'appel';

  @override
  String get cdr_disconnectReason_userBusy => 'Utilisateur occupé';

  @override
  String get cdr_disconnectReason_noUserResponding => 'Aucun utilisateur ne répond';

  @override
  String get cdr_disconnectReason_noAnswerFromUser => 'Pas de réponse de l\'utilisateur';

  @override
  String get cdr_disconnectReason_subscriberIsAbsent => 'Abonné absent';

  @override
  String get cdr_disconnectReason_callRejected => 'Appel refusé';

  @override
  String get cdr_disconnectReason_numberChanged => 'Numéro modifié';

  @override
  String get cdr_disconnectReason_reverseChargingRejected => 'Facturation à l\'appelant refusée';

  @override
  String get cdr_disconnectReason_callSuspended => 'Appel suspendu';

  @override
  String get cdr_disconnectReason_callResumed => 'Appel repris';

  @override
  String get cdr_disconnectReason_nonSelectedUserClearing => 'Libération par un utilisateur non sélectionné';

  @override
  String get cdr_disconnectReason_destinationOutOfOrder => 'Destination hors service';

  @override
  String get cdr_disconnectReason_invalidNumberFormatIncompleteNumber => 'Format de numéro invalide (numéro incomplet)';

  @override
  String get cdr_disconnectReason_facilityRejected => 'Service refusé';

  @override
  String get cdr_disconnectReason_responseToStatusEnquiry => 'Réponse à STATUS ENQUIRY';

  @override
  String get cdr_disconnectReason_normalUnspecified => 'Normal, non spécifié';

  @override
  String get cdr_disconnectReason_circuitOutOfOrder => 'Circuit hors service';

  @override
  String get cdr_disconnectReason_noCircuitChannelAvailable => 'Aucun circuit/canal disponible';

  @override
  String get cdr_disconnectReason_destinationUnattainableRequireVpciVciIsNotAvailable =>
      'Destination injoignable (VPCI/VCI requis non disponible)';

  @override
  String get cdr_disconnectReason_vpciVciAssignmentFailure => 'Échec d\'attribution VPCI/VCI';

  @override
  String get cdr_disconnectReason_degradedServiceCallRateIsnNotValid => 'Service dégradé (débit d\'appel non valide)';

  @override
  String get cdr_disconnectReason_networkWanOutOfOrder => 'Réseau (WAN) hors service';

  @override
  String get cdr_disconnectReason_transitDelayRangeCannotBeAchievedPermanentFrameModeIsOutOfService =>
      'Plage de délai de transit inatteignable (mode trame permanent hors service)';

  @override
  String get cdr_disconnectReason_throughputRangeCannotBeAchievedPermanentFrameModeIsOperational =>
      'Plage de débit inatteignable (mode trame permanent opérationnel)';

  @override
  String get cdr_disconnectReason_temporaryFailure => 'Panne temporaire';

  @override
  String get cdr_disconnectReason_switchingEquipmentCongestion => 'Congestion de l\'équipement de commutation';

  @override
  String get cdr_disconnectReason_accessInformationDiscarded => 'Informations d\'accès rejetées';

  @override
  String get cdr_disconnectReason_requestedCircuitChannelNotAvailable => 'Circuit/canal demandé non disponible';

  @override
  String get cdr_disconnectReason_preEmptedNoVpciVciIsAvailable => 'Préempté (aucun VPCI/VCI disponible)';

  @override
  String get cdr_disconnectReason_precedenceCallBlocked => 'Appel prioritaire bloqué';

  @override
  String get cdr_disconnectReason_resourceUnavailableUnspecified => 'Ressource non disponible - non spécifié';

  @override
  String get cdr_disconnectReason_dspError => 'Erreur DSP';

  @override
  String get cdr_disconnectReason_qualityOfServiceUnavailable => 'Qualité de service non disponible';

  @override
  String get cdr_disconnectReason_requestedFacilityNotSubscribed => 'Service demandé non souscrit';

  @override
  String get cdr_disconnectReason_reverseChargingNotAllowed => 'Facturation à l\'appelant non autorisée';

  @override
  String get cdr_disconnectReason_outgoingCallsBarred => 'Appels sortants bloqués';

  @override
  String get cdr_disconnectReason_outgoingCallsBarredWithinCug => 'Appels sortants bloqués au sein du CUG';

  @override
  String get cdr_disconnectReason_incomingCallsBarred => 'Appels entrants bloqués';

  @override
  String get cdr_disconnectReason_incomingCallsBarredWithinCug => 'Appels entrants bloqués au sein du CUG';

  @override
  String get cdr_disconnectReason_callWaitingNotSubscribed => 'Appel en attente non souscrit';

  @override
  String get cdr_disconnectReason_bearerCapabilityNotAuthorized => 'Capacité de support non autorisée';

  @override
  String get cdr_disconnectReason_bearerCapabilityNotPresentlyAvailable =>
      'Capacité de support actuellement non disponible';

  @override
  String get cdr_disconnectReason_inconsistancyInTheInformationAndClass =>
      'Incohérence entre l\'information et la classe';

  @override
  String get cdr_disconnectReason_serviceOrOptionNotAvailableUnspecified =>
      'Service ou option non disponible, non spécifié';

  @override
  String get cdr_disconnectReason_bearerServiceNotImplemented => 'Service bearer non implémenté';

  @override
  String get cdr_disconnectReason_channelTypeNotImplemented => 'Type de canal non implémenté';

  @override
  String get cdr_disconnectReason_transitNetworkSelectionNotImplemented =>
      'Sélection du réseau de transit non implémentée';

  @override
  String get cdr_disconnectReason_messageNotImplemented => 'Message non implémenté';

  @override
  String get cdr_disconnectReason_requestedFacilityNotImplemented => 'Service demandé non implémenté';

  @override
  String get cdr_disconnectReason_onlyRestrictedDigitalInformationBearerCapabilityIsAvailable =>
      'Seule la capacité bearer d\'information numérique restreinte est disponible';

  @override
  String get cdr_disconnectReason_serviceOrOptionNotImplementedUnspecified =>
      'Service ou option non implémenté, non spécifié';

  @override
  String get cdr_disconnectReason_invalidCallReferenceValue => 'Valeur de référence d\'appel invalide';

  @override
  String get cdr_disconnectReason_identifiedChannelDoesNotExist => 'Le canal identifié n\'existe pas';

  @override
  String get cdr_disconnectReason_aSuspendedCallExistsButThisCallIdentityDoesNot =>
      'Un appel suspendu existe, mais cette identité d\'appel n\'existe pas';

  @override
  String get cdr_disconnectReason_callIdentityInUse => 'Identité d\'appel déjà utilisée';

  @override
  String get cdr_disconnectReason_noCallSuspended => 'Aucun appel suspendu';

  @override
  String get cdr_disconnectReason_callHavingTheRequestedCallIdentityHasBeenCleared =>
      'L\'appel ayant l\'identité d\'appel demandée a été libéré';

  @override
  String get cdr_disconnectReason_calledUserNotMemberOfCug => 'L\'utilisateur appelé n\'est pas membre du CUG';

  @override
  String get cdr_disconnectReason_incompatibleDestination => 'Destination incompatible';

  @override
  String get cdr_disconnectReason_nonExistentAbbreviatedAddressEntry => 'Entrée d\'adresse abrégée inexistante';

  @override
  String get cdr_disconnectReason_destinationAddressMissingAndDirectCallNotSubscribed =>
      'Adresse de destination manquante et appel direct non souscrit';

  @override
  String get cdr_disconnectReason_invalidTransitNetworkSelectionNationalUse =>
      'Sélection de réseau de transit invalide (usage national)';

  @override
  String get cdr_disconnectReason_invalidFacilityParameter => 'Paramètre de service invalide';

  @override
  String get cdr_disconnectReason_mandatoryInformationElementIsMissingAalParameterIsNotSupported =>
      'Élément d\'information obligatoire manquant (paramètre AAL non pris en charge)';

  @override
  String get cdr_disconnectReason_invalidMessageUnspecified => 'Message invalide, non spécifié';

  @override
  String get cdr_disconnectReason_mandatoryInformationElementIsMissing => 'Élément d\'information obligatoire manquant';

  @override
  String get cdr_disconnectReason_messageTypeNonExistentOrNotImplemented =>
      'Type de message inexistant ou non implémenté';

  @override
  String get cdr_disconnectReason_messageNotCompatibleWithCallStateOrMessageTypeNonExistentOrNotImplemented =>
      'Message incompatible avec l\'état de l\'appel ou type de message inexistant ou non implémenté';

  @override
  String get cdr_disconnectReason_informationElementNonexistantOrNotImplemented =>
      'élément d\'information inexistant ou non implémenté';

  @override
  String get cdr_disconnectReason_invalidInformationElementContents => 'Contenu d\'élément d\'information invalide';

  @override
  String get cdr_disconnectReason_messageNotCompatibleWithCallState => 'Message incompatible avec l\'état de l\'appel';

  @override
  String get cdr_disconnectReason_recoveryOnTimerExpiry => 'Reprise à l\'expiration du minuteur';

  @override
  String get cdr_disconnectReason_parameterNonExistentOrNotImplementedPassedOn =>
      'paramètre inexistant ou non implémenté - transmis';

  @override
  String get cdr_disconnectReason_urecognizedParameterMessageDiscarded => 'Message de paramètre non reconnu rejeté';

  @override
  String get cdr_disconnectReason_protocolErrorUnspecified => 'Erreur de protocole non spécifiée';

  @override
  String get cdr_disconnectReason_internetworkingUnspecified => 'Interconnexion, non spécifié';

  @override
  String get cdr_disconnectReason_nextNodeIsUnreachable => 'Le nœud suivant est injoignable';

  @override
  String get cdr_disconnectReason_holstTelephonyServiceProviderModuleHtspmIsOutOfService =>
      'Le module fournisseur de services téléphoniques Holst (HTSPM) est hors service';

  @override
  String get cdr_disconnectReason_dtlTransitIsNotMyNodeId => 'Le transit DTL n\'est pas mon ID de nœud';

  @override
  String get devTools_AppBarTitle => 'Outils de développement';

  @override
  String get devTools_signalingService_groupTitle => 'Service de signalisation';

  @override
  String get devTools_signalingService_simulateKill_title => 'Simuler l\'arrêt du service';

  @override
  String get devTools_signalingService_simulateKill_subtitle =>
      'Arrête le service de premier plan sans déconnexion propre';

  @override
  String get devTools_signalingService_simulateKill_confirmMessage =>
      'Le service de signalisation va s\'arrêter immédiatement. Il redémarrera automatiquement si les identifiants sont valides.';

  @override
  String get devTools_signalingService_simulateKill_confirm => 'Arrêter';

  @override
  String get devTools_signalingService_simulateKill_cancel => 'Annuler';

  @override
  String get devTools_systemInfo_groupTitle => 'Détails du serveur';

  @override
  String get devTools_systemInfo_clear_title => 'Effacer les détails du serveur enregistrés';

  @override
  String get devTools_systemInfo_clear_subtitle =>
      'Ferme l\'application ; au prochain démarrage, ils sont chargés en premier, comme après une mise à jour';

  @override
  String get devTools_systemInfo_clear_confirmMessage =>
      'Les détails du serveur enregistrés sont effacés et l\'application se ferme. Rouvrez-la pour démarrer sans eux.';

  @override
  String get devTools_systemInfo_clear_confirm => 'Effacer et fermer';

  @override
  String get devTools_systemInfo_clear_cancel => 'Annuler';

  @override
  String get common_SemanticsLabel_refresh => 'Actualiser';

  @override
  String get common_SemanticsLabel_scrollToBottom => 'Aller en bas';

  @override
  String get common_SemanticsLabel_scrollToTop => 'Aller en haut';

  @override
  String common_SemanticsValue_unreadCount(int count) {
    return '$count non lus';
  }

  @override
  String common_SemanticsValue_totalCount(int count) {
    return '$count au total';
  }

  @override
  String common_SemanticsValue_selectedCount(int count) {
    return '$count sélectionnés';
  }

  @override
  String get contacts_SemanticsLabel_clearSearch => 'Effacer la recherche';

  @override
  String get contacts_SemanticsLabel_closeSearch => 'Fermer la recherche';

  @override
  String get messaging_SemanticsLabel_newChat => 'Démarrer une nouvelle discussion';

  @override
  String get messaging_SemanticsLabel_newSms => 'Écrire un nouveau message';

  @override
  String get messaging_SemanticsLabel_call => 'Appeler';

  @override
  String get messaging_SemanticsLabel_videoCall => 'Appel vidéo';

  @override
  String get messaging_SemanticsLabel_message => 'Message';

  @override
  String get messaging_SemanticsLabel_send => 'Envoyer';

  @override
  String get messaging_SemanticsLabel_conversationDetails => 'Détails de la discussion';

  @override
  String get messaging_SemanticsLabel_conversationOptions => 'Options de la discussion';

  @override
  String get messaging_SemanticsLabel_muted => 'Notifications silencieuses';

  @override
  String get messaging_SemanticsLabel_replying => 'En réponse à';

  @override
  String get messaging_SemanticsLabel_editing => 'Modification en cours';

  @override
  String get messaging_SemanticsLabel_forwarding => 'Transfert en cours';

  @override
  String get messaging_SemanticsLabel_stopReplying => 'Arrêter la réponse';

  @override
  String get messaging_SemanticsLabel_stopEditing => 'Arrêter la modification';

  @override
  String get messaging_SemanticsLabel_stopForwarding => 'Arrêter le transfert';

  @override
  String get messaging_SemanticsLabel_sendForward => 'Transférer le message';

  @override
  String callPull_SemanticsLabel_badge(String name) {
    return 'Reprendre l\'appel avec $name';
  }

  @override
  String callPull_SemanticsLabel_badgeSeveral(int count) {
    return 'Reprendre l\'un des $count appels';
  }

  @override
  String callPull_SemanticsLabel_pickup(String name) {
    return 'Décrocher l\'appel avec $name';
  }

  @override
  String get diagnosticNetworkTest_SemanticsLabel_refresh => 'Relancer le test réseau';

  @override
  String get presence_settings_statusIcon_searchHint => 'Rechercher des icônes';

  @override
  String presenceSettings_SemanticsLabel_optionInfo(String option) {
    return 'Signification de $option';
  }

  @override
  String get presenceSettings_SemanticsLabel_preset => 'Préréglage de statut';

  @override
  String get presenceSettings_SemanticsLabel_pickStatusIcon => 'Choisir une icône de statut';

  @override
  String get presenceSettings_SemanticsLabel_clearStatusIcon => 'Retirer l\'icône de statut';

  @override
  String get presenceSettings_SemanticsLabel_searchIcons => 'Rechercher des icônes';

  @override
  String get presenceSettings_SemanticsLabel_stopSearchingIcons => 'Arrêter la recherche d\'icônes';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryRecent => 'Récemment utilisées';

  @override
  String get presenceSettings_SemanticsLabel_iconCategorySmileys => 'Émoticônes et personnes';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryAnimals => 'Animaux et nature';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryFoods => 'Nourriture et boissons';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryActivities => 'Activités';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryTravel => 'Voyages et lieux';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryObjects => 'Objets';

  @override
  String get presenceSettings_SemanticsLabel_iconCategorySymbols => 'Symboles';

  @override
  String get presenceSettings_SemanticsLabel_iconCategoryFlags => 'Drapeaux';
}
