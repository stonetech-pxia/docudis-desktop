// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Docudis';

  @override
  String get signInTitle => '登录';

  @override
  String get signUpTitle => '注册账号';

  @override
  String get forgotPasswordTitle => '重置密码';

  @override
  String get emailLabel => '邮箱';

  @override
  String get passwordLabel => '密码';

  @override
  String get confirmPasswordLabel => '确认密码';

  @override
  String get signInButton => '登录';

  @override
  String get signUpButton => '注册';

  @override
  String get forgotPasswordLink => '忘记密码？';

  @override
  String get forgotPasswordHint => '输入你的邮箱地址，我们会发送一封重置密码的邮件。';

  @override
  String get sendResetEmailButton => '发送重置邮件';

  @override
  String get resetEmailSent => '重置密码邮件已发送，请查收邮箱。';

  @override
  String get continueWithGoogle => '使用 Google 登录';

  @override
  String get continueWithApple => '通过 Apple 登录';

  @override
  String get orDivider => '或';

  @override
  String get noAccountYet => '还没有账号？';

  @override
  String get alreadyHaveAccount => '已有账号？';

  @override
  String get signOut => '退出登录';

  @override
  String get validationEmailRequired => '请输入邮箱地址。';

  @override
  String get validationEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get validationPasswordRequired => '请输入密码。';

  @override
  String validationPasswordTooShort(int min) {
    return '密码至少需要 $min 位。';
  }

  @override
  String get validationPasswordsDoNotMatch => '两次输入的密码不一致。';

  @override
  String get authErrorInvalidEmail => '邮箱地址无效。';

  @override
  String get authErrorUserDisabled => '该账号已被停用。';

  @override
  String get authErrorUserNotFound => '找不到使用该邮箱的账号。';

  @override
  String get authErrorWrongPassword => '邮箱或密码错误。';

  @override
  String get authErrorEmailInUse => '该邮箱已被注册。';

  @override
  String get authErrorWeakPassword => '密码强度太弱。';

  @override
  String get authErrorOperationNotAllowed => '该登录方式尚未启用。';

  @override
  String get authErrorTooManyRequests => '尝试次数过多，请稍后再试。';

  @override
  String get authErrorNetwork => '网络错误，请检查网络连接后重试。';

  @override
  String get authErrorAccountExistsWithDifferentCredential => '该邮箱已通过其他登录方式注册。';

  @override
  String get authErrorGeneric => '出了点问题，请重试。';

  @override
  String homeSignedInAs(String email) {
    return '当前账号：$email';
  }

  @override
  String get anonymizeTitle => '保护';

  @override
  String get inputPasteText => '粘贴文本';

  @override
  String get inputPickFile => '上传文档';

  @override
  String get inputTakePhoto => '照片识别';

  @override
  String get photoFromCamera => '拍照';

  @override
  String get photoFromLibrary => '从相册选择';

  @override
  String get processing => '正在读取并匿名化…';

  @override
  String get historyTitle => '历史记录';

  @override
  String get historyEmpty => '还没有处理过任何内容。';

  @override
  String get resultTitle => '受保护副本';

  @override
  String get tabAnonymized => '匿名化后';

  @override
  String get tabOriginal => '原文';

  @override
  String get shareFile => '分享文件';

  @override
  String get sharedImageName => '匿名化图片';

  @override
  String get shareText => '分享文本';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制。';

  @override
  String detectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 处敏感信息',
      zero: '没有敏感信息',
    );
    return '$_temp0';
  }

  @override
  String get noDetections => '没有发现敏感信息。';

  @override
  String get delete => '删除';

  @override
  String get deleteRecordConfirm => '删除这条记录及其还原密钥？';

  @override
  String get deleteAll => '全部删除';

  @override
  String get deleteAllConfirm => '删除全部历史记录？此操作无法撤销。';

  @override
  String get cancel => '取消';

  @override
  String get restoreTitle => '还原';

  @override
  String get restoreHint => '粘贴 AI 的回复，标签会用本机保存的密钥换回真实信息。';

  @override
  String get entityPerson => '人名';

  @override
  String get entityEmail => '邮箱';

  @override
  String get entityPhone => '电话';

  @override
  String get entityId => '证件号';

  @override
  String get entityCard => '卡号';

  @override
  String get entityIban => 'IBAN';

  @override
  String get entityDate => '日期';

  @override
  String get entityAmount => '金额';

  @override
  String get entityIp => 'IP 地址';

  @override
  String get entityUrl => '网址';

  @override
  String get entityAddress => '地址 / 地点';

  @override
  String get entityCompany => '机构';

  @override
  String get entitySecret => '密钥 / 凭据';

  @override
  String get entityCustom => '自定义关键词';

  @override
  String get entityOther => '其他';

  @override
  String get errorNoText => '无法从该输入中读取文字。';

  @override
  String get errorUnsupportedFile => '暂不支持该文件类型。';

  @override
  String get errorProcessingFailed => '处理失败，请重试。';

  @override
  String get navAccount => '账户';

  @override
  String get reviewTitle => '改一改遮住的内容';

  @override
  String get reviewHint => '点占位符可看回原文；点人名、号码等任意文字就把它遮住。改动即时保存。';

  @override
  String get reviewHideAmounts => '遮住全部金额';

  @override
  String get reviewHideDates => '遮住全部日期';

  @override
  String get reviewNote => '会替换成 [PERSON_1] 这样的标签，AI 的回答仍然连贯。';

  @override
  String get done => '完成';

  @override
  String resultBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已替换 $count 处。',
      zero: '没有需要替换的内容。',
    );
    return '$_temp0';
  }

  @override
  String get restoreKeyTitle => '还原密钥保存在本机';

  @override
  String restoreKeySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 组映射 · 从不上传 · 随时可删除',
    );
    return '$_temp0';
  }

  @override
  String get copyText => '复制文本';

  @override
  String sendTo(String app) {
    return '发送到 $app';
  }

  @override
  String get aiReplyLabel => 'AI 回复';

  @override
  String get paste => '粘贴';

  @override
  String get restoredLabel => '已还原';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已还原 $count 个标签。',
      zero: '没有找到可还原的标签。',
    );
    return '$_temp0';
  }

  @override
  String get restoreDocumentLabel => '文档';

  @override
  String get restoreMismatchTitle => '这条回复和这份文档对不上';

  @override
  String restoreMismatchBody(String labels) {
    return '回复里有这份文档从未用过的标签：$labels。它多半是另一份文档的回复，请从历史记录里打开那份文档再还原。';
  }

  @override
  String get restoreShowAnyway => '仍然显示';

  @override
  String get restoreOtherTitle => '这条回复像是另一份文档的';

  @override
  String restoreOtherBody(String name) {
    return '它的标签和内容更符合「$name」。在这里还原，会填进这份文档的姓名和号码。';
  }

  @override
  String get restoreUseOther => '改用那份文档还原';

  @override
  String restoreInvented(String labels) {
    return '这份文档里没有，保持原样：$labels';
  }

  @override
  String restoreShownAnyway(String name) {
    return '已用这份文档的密钥还原，但这条回复更符合「$name」。';
  }

  @override
  String get copyRestored => '复制还原后的文本';

  @override
  String get clipboardEmpty => '剪贴板里没有文字。';

  @override
  String get confirm => '确认';

  @override
  String get homeHeadline => '把个人数据匿名化，保护起来。';

  @override
  String get homeCaption => '完全在本机运行，不会上传任何内容。';

  @override
  String get anonymizeButton => '匿名化';

  @override
  String get sendToLabel => '发送到';

  @override
  String get otherApps => '其他';

  @override
  String get otherAppsTitle => '其他 AI 应用';

  @override
  String get sharedFileName => '匿名化文本';

  @override
  String get sharedDocumentName => '匿名化文档';

  @override
  String get clearData => '清除本机数据';

  @override
  String clearDataHint(int count) {
    return '本机保留最近 $count 条处理记录，清除后全部删除。';
  }

  @override
  String get clearDataConfirm => '删除本机所有处理记录？此操作无法撤销。';

  @override
  String get clearDataAction => '清除';

  @override
  String get dataCleared => '已清除本机数据。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get dictionaryTitle => '总是遮住';

  @override
  String get dictionaryHint =>
      '输入每份文档都要遮住的内容，比如你自己的姓名、公司或地址。列表只存在本机，在单份文档里仍可以让某一项重新显示。';

  @override
  String get dictionaryEmpty => '还没有内容。你手动遮住的文字会在这里推荐。';

  @override
  String dictionaryWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个词',
      zero: '还没有词',
    );
    return '$_temp0';
  }

  @override
  String dictionarySuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条推荐',
    );
    return '$_temp0';
  }

  @override
  String get dictionarySuggested => '最近手动遮住的';

  @override
  String get dictionarySeeAll => '所有';

  @override
  String get dictionaryAllTitle => '手动遮住的文字';

  @override
  String dictionaryAllHint(int count) {
    return '最近手动遮住的文字，最多 $count 条。点一下就加入“总是遮住”。';
  }

  @override
  String get dictionaryAllEmpty => '暂时没有可推荐的。';

  @override
  String dictionaryAdd(String term) {
    return '总是遮住 $term';
  }

  @override
  String dictionaryRemove(String term) {
    return '不再遮住 $term';
  }

  @override
  String get rename => '重命名';

  @override
  String get save => '保存';

  @override
  String get moreActions => '更多';

  @override
  String get dictionaryInputHint => '姓名、公司、地址…';

  @override
  String get dictionaryAddButton => '添加';

  @override
  String get listOnlyTitle => '只遮住这个列表';

  @override
  String get listOnlyHint => '会关闭自动识别，列表以外的内容都不遮住。';

  @override
  String get listOnlyNeedsWords => '请先在列表里添加一个词。';

  @override
  String get listOnlyConfirmTitle => '只遮住这个列表？';

  @override
  String get listOnlyConfirmBody =>
      'Docudis 将不再自动查找个人信息，只遮住这个列表里的词。\n\n大小写和重音不影响匹配，但写法不同就认不出：列表里的「Jean Dupont」遮不住「Mr Dupont」或「DUPONT J.」，空格位置不同的电话号码也会照样显示。\n\n列表以外的内容都保持可见，比如其他人的姓名（医生、房东、亲属）、账号、档案号、参考号和出生日期。\n\n发送前请逐一检查结果。你可以随时关闭这个选项。';

  @override
  String get listOnlyConfirmAction => '只遮住我的列表';

  @override
  String get listOnlyCaption => '只遮住这些';

  @override
  String get resultListOnlyNote => '只用了你的“总是遮住”列表，其他内容没有检查：发送前请先通读一遍。';

  @override
  String get neverHideTitle => '从不遮住';

  @override
  String get neverHideHint =>
      '有些公开名称其实不必遮住，比如市政府、银行或品牌。从下一份文档起，这个列表里的内容保持可见；包含它的更长名称或地址仍会遮住。';

  @override
  String get neverHideEmpty => '还没有。你手动恢复显示的名称会出现在这里作为推荐。';

  @override
  String get neverHideInputHint => '市政府、银行、品牌…';

  @override
  String get neverHideSuggested => '最近手动恢复显示的';

  @override
  String neverHideAdd(String term) {
    return '从不遮住 $term';
  }

  @override
  String neverHideRemove(String term) {
    return '重新遮住 $term';
  }

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get privacyPolicyHint => '你的文档如何处理';

  @override
  String get contactUs => '联系我们';

  @override
  String appVersion(String version, String build) {
    return 'Docudis $version（$build）';
  }
}
