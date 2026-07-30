import 'package:flutter/widgets.dart';

class LegalSectionContent {
  const LegalSectionContent({
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  final String title;
  final String body;
  final List<String> bullets;
}

class LegalDocumentContent {
  const LegalDocumentContent({
    required this.title,
    required this.updated,
    required this.sections,
  });

  final String title;
  final String updated;
  final List<LegalSectionContent> sections;
}

class LegalCopyContent {
  const LegalCopyContent({
    required this.privacy,
    required this.terms,
    required this.accountDeletionLink,
  });

  final LegalDocumentContent privacy;
  final LegalDocumentContent terms;
  final String accountDeletionLink;
}

LegalCopyContent legalCopyFor(Locale locale) =>
    appLegalCopy[locale.languageCode] ?? appLegalCopy['en']!;

const appLegalCopy = <String, LegalCopyContent>{
  "en": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Privacy Policy",
      updated: "Effective July 31, 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Information we collect",
          body:
              "We collect information needed to operate HOK Helper and keep accounts synchronized.",
          bullets: [
            "Account and profile data, including email, username, display name, avatar, signature, social links, and identifiers returned by Google, Discord, or Apple when you choose those sign-in methods.",
            "Content and activity you choose to create, including posts, comments, prompts, uploaded images, build, tier-list and BP schemes, follows, likes, favorites, reports, and blocks.",
            "Preferences and technical data, including language, region, theme, session tokens, IP address, user agent, request logs, diagnostics, and basic usage events.",
            "Public gameplay or esports data and any game identifier you voluntarily provide. HOK Helper does not request your game password.",
          ],
        ),
        LegalSectionContent(
          title: "2. How we use information",
          body:
              "We use information to authenticate users, provide and synchronize features, personalize regional content, secure the service, moderate abuse, respond to support requests, diagnose failures, and improve performance. We do not sell personal information.",
        ),
        LegalSectionContent(
          title: "3. Public content and community safety",
          body:
              "Public posts, comments, profiles, prompts, and public schemes may be visible to other users and may appear in search results. Reports and blocks are used to investigate abuse and hide unwanted content. Authorized moderators may remove content or restrict accounts under our Terms.",
        ),
        LegalSectionContent(
          title: "4. Service providers and disclosures",
          body:
              "We disclose only the information necessary for providers to perform their services.",
          bullets: [
            "Google, Discord, and Apple may process authentication data when you use their sign-in services.",
            "Cloudflare and infrastructure providers process network traffic, security signals, logs, and stored media.",
            "AI providers process prompts or images only when you explicitly invoke an AI-powered feature.",
            "App stores may process installation, distribution, billing, and crash information under their own policies.",
            "We may disclose information when required by law, to protect users, or during a business transfer with appropriate safeguards.",
          ],
        ),
        LegalSectionContent(
          title: "5. Storage, security, and retention",
          body:
              "Authentication tokens are stored using platform-protected storage. We use access controls, HTTPS, monitoring, and backups, but no system can guarantee absolute security. Account data is retained while the account is active; content, safety reports, operational logs, and backups are retained only as long as reasonably needed for service, security, legal, and dispute purposes.",
        ),
        LegalSectionContent(
          title: "6. Your choices and rights",
          body:
              "You may update profile information, manage blocked users, remove eligible content, and permanently delete your account in the app or through the account-deletion page. Depending on your location, you may also request access, correction, portability, restriction, or objection by contacting hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Children and international processing",
          body:
              "HOK Helper is not directed to children under 13 or below the minimum digital-consent age in their country. If we learn that prohibited child data was collected, we will delete it. Information may be processed in countries other than your own with contractual, technical, and organizational safeguards.",
        ),
        LegalSectionContent(
          title: "8. Changes and contact",
          body:
              "We may update this policy when features, providers, or legal requirements change. Material changes will be announced in the service where practical. Questions and privacy requests can be sent to hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Terms of Service",
      updated: "Effective July 31, 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Acceptance and eligibility",
          body:
              "By using HOK Helper, you agree to these Terms and the Privacy Policy. You must meet the minimum age required in your country and have authority to accept these Terms.",
        ),
        LegalSectionContent(
          title: "2. Acceptable use",
          body:
              "Do not use HOK Helper to break the law, exploit or disrupt the service, evade security, impersonate others, automate abusive traffic, cheat in live games, or infringe intellectual-property or privacy rights.",
        ),
        LegalSectionContent(
          title: "3. User-generated content",
          body:
              "You retain ownership of content you submit and grant HOK Helper a worldwide, non-exclusive, royalty-free license to host, reproduce, format, translate, display, and distribute it only as needed to operate and promote the service. You must have the necessary rights to anything you upload.",
          bullets: [
            "Sexual exploitation, threats, hate, harassment, scams, illegal content, malware, and deliberate misinformation are prohibited.",
            "Use in-app reporting and blocking tools for safety concerns. We may review reports, remove content, preserve evidence, or suspend accounts.",
            "Repeated or severe violations may result in immediate termination and referral to relevant authorities.",
          ],
        ),
        LegalSectionContent(
          title: "4. Game data, AI, and third-party services",
          body:
              "Statistics, recommendations, translations, AI output, and community advice may be incomplete or inaccurate and are provided for informational purposes. HOK Helper is independent from TiMi Studio Group, Tencent, and Level Infinite. Third-party services and links are governed by their own terms.",
        ),
        LegalSectionContent(
          title: "5. Accounts and termination",
          body:
              "Keep your device and account credentials secure. You are responsible for activity under your account. You may delete your account at any time. We may restrict or terminate access for violations, security threats, legal requirements, or discontinuation of the service.",
        ),
        LegalSectionContent(
          title: "6. Digital features and store billing",
          body:
              "If paid digital features are offered in a mobile build, checkout, refunds, and subscription management will follow the applicable Apple App Store or Google Play rules. Store purchases do not transfer ownership of HOK Helper software or content.",
        ),
        LegalSectionContent(
          title: "7. Availability and liability",
          body:
              "The service is provided on an “as available” basis without guarantees of uninterrupted access, rank improvement, competitive results, or data accuracy. To the extent permitted by law, HOK Helper is not liable for indirect or consequential losses arising from use of the service.",
        ),
        LegalSectionContent(
          title: "8. Changes and contact",
          body:
              "We may update these Terms and will provide reasonable notice of material changes. Continued use after the effective date means you accept the revised Terms. Contact hokhelper@163.com with questions.",
        ),
      ],
    ),
    accountDeletionLink: "Delete your HOK Helper account and associated data",
  ),
  "zh": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "隐私政策",
      updated: "生效日期：2026 年 7 月 31 日。",
      sections: [
        LegalSectionContent(
          title: "1. 我们收集的信息",
          body: "我们仅收集运营 HOK Helper 和同步账户所需的信息。",
          bullets: [
            "账户与资料：邮箱、用户名、昵称、头像、签名、社媒链接，以及选择 Google、Discord 或 Apple 登录时返回的标识。",
            "你主动创建的帖子、评论、提示词、上传图片、出装、梯度和 BP 方案，以及关注、点赞、收藏、举报和屏蔽记录。",
            "语言、地区、主题、会话令牌、IP、User-Agent、请求日志、诊断和基础使用事件。",
            "公开的游戏或电竞数据及你自愿提供的游戏标识；我们不会索取游戏密码。",
          ],
        ),
        LegalSectionContent(
          title: "2. 信息用途",
          body: "用于身份验证、功能同步、地区个性化、安全防护、内容审核、客服、故障诊断和性能优化。我们不会出售个人信息。",
        ),
        LegalSectionContent(
          title: "3. 公开内容与社区安全",
          body:
              "公开资料、帖子、评论、提示词和公开方案可能被其他用户或搜索引擎看到。举报和屏蔽用于调查滥用、隐藏内容；授权审核员可依据条款移除内容或限制账户。",
        ),
        LegalSectionContent(
          title: "4. 服务商与披露",
          body:
              "Google、Discord、Apple 可能处理登录数据；Cloudflare 和基础设施服务商处理流量、安全信号、日志与媒体；仅在你主动使用 AI 功能时，AI 服务商才会处理相关提示词或图片。应用商店按其政策处理分发、支付和崩溃信息。法律要求或保护用户时也可能披露必要信息。",
        ),
        LegalSectionContent(
          title: "5. 存储、安全与保留",
          body:
              "令牌保存在系统安全存储中，并采用 HTTPS、访问控制、监控和备份。不存在绝对安全的系统。账户数据在账户有效期内保留；内容、安全举报、运维日志和备份仅按服务、安全、法律及争议处理所需期限保留。",
        ),
        LegalSectionContent(
          title: "6. 你的选择与权利",
          body:
              "你可修改资料、管理屏蔽用户、删除符合条件的内容，并在 App 或账户删除页面永久删除账户。根据所在地法律，你还可通过 hokhelper@163.com 请求访问、更正、可携带、限制处理或提出异议。",
        ),
        LegalSectionContent(
          title: "7. 儿童与跨境处理",
          body:
              "本服务不面向 13 岁以下或未达到当地数字同意年龄的儿童。发现违规收集后会删除。数据可能在境外处理，并采取合同、技术和组织保护措施。",
        ),
        LegalSectionContent(
          title: "8. 变更与联系",
          body: "功能、服务商或法律变化时可能更新本政策，重大变化会尽可能在服务内通知。隐私问题请联系 hokhelper@163.com。",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "服务条款",
      updated: "生效日期：2026 年 7 月 31 日。",
      sections: [
        LegalSectionContent(
          title: "1. 接受与资格",
          body: "使用 HOK Helper 即表示你同意本条款和隐私政策，并已达到所在地最低年龄且有权接受条款。",
        ),
        LegalSectionContent(
          title: "2. 可接受使用",
          body: "不得违法使用、破坏服务、规避安全、冒充他人、制造滥用流量、在实时游戏中作弊，或侵犯知识产权与隐私。",
        ),
        LegalSectionContent(
          title: "3. 用户生成内容",
          body:
              "你保留内容所有权，并授予 HOK Helper 为运营和推广服务所需的全球、非独占、免版税托管、复制、排版、翻译、展示和分发许可。你必须拥有上传内容的必要权利。禁止性剥削、威胁、仇恨、骚扰、诈骗、违法内容、恶意软件和故意虚假信息。我们可审核举报、删除内容、保留证据、暂停账户，并在严重情况下向主管机关报告。",
        ),
        LegalSectionContent(
          title: "4. 游戏数据、AI 与第三方",
          body:
              "统计、推荐、翻译、AI 输出和社区建议可能不完整或不准确，仅供参考。HOK Helper 与腾讯、天美和 Level Infinite 无官方从属关系。第三方服务适用其自身条款。",
        ),
        LegalSectionContent(
          title: "5. 账户与终止",
          body: "请保护设备和账户安全，你对账户活动负责。你可随时删除账户；违规、安全威胁、法律要求或服务停止时，我们可限制或终止访问。",
        ),
        LegalSectionContent(
          title: "6. 数字功能与商店支付",
          body:
              "如移动版提供付费数字功能，结算、退款和订阅管理遵循 Apple App Store 或 Google Play 规则。购买不转移软件或内容所有权。",
        ),
        LegalSectionContent(
          title: "7. 可用性与责任",
          body: "服务按现状提供，不保证持续可用、提升段位、比赛结果或数据绝对准确。在法律允许范围内，我们不承担间接或后果性损失。",
        ),
        LegalSectionContent(
          title: "8. 变更与联系",
          body: "重大条款变更会合理通知，生效后继续使用即表示接受。问题请联系 hokhelper@163.com。",
        ),
      ],
    ),
    accountDeletionLink: "删除 HOK Helper 账户及关联数据",
  ),
  "id": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Kebijakan Privasi",
      updated: "Berlaku 31 Juli 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Informasi yang kami kumpulkan",
          body:
              "Kami mengumpulkan data yang diperlukan untuk menjalankan layanan: email, profil, ID OAuth Google/Discord/Apple, konten dan gambar yang Anda unggah, skema, interaksi, laporan/blokir, preferensi, token sesi, IP, user-agent, log, diagnostik, serta ID game yang Anda berikan secara sukarela. Kami tidak meminta kata sandi game.",
        ),
        LegalSectionContent(
          title: "2. Cara kami menggunakan data",
          body:
              "Data dipakai untuk autentikasi, sinkronisasi, personalisasi wilayah, keamanan, moderasi, dukungan, diagnosis, dan peningkatan layanan. Kami tidak menjual data pribadi.",
        ),
        LegalSectionContent(
          title: "3. Konten publik dan keselamatan",
          body:
              "Profil dan konten publik dapat dilihat pengguna lain atau mesin pencari. Laporan dan blokir membantu menyembunyikan serta menyelidiki penyalahgunaan; moderator dapat menghapus konten atau membatasi akun.",
        ),
        LegalSectionContent(
          title: "4. Penyedia layanan",
          body:
              "Google, Discord, dan Apple memproses login; Cloudflare dan penyedia infrastruktur memproses trafik, log, keamanan, dan media; penyedia AI hanya menerima prompt/gambar saat fitur AI digunakan; toko aplikasi memproses distribusi dan pembayaran sesuai kebijakan mereka.",
        ),
        LegalSectionContent(
          title: "5. Penyimpanan dan retensi",
          body:
              "Token disimpan dengan penyimpanan aman platform. Kami memakai HTTPS, kontrol akses, pemantauan, dan cadangan. Data disimpan hanya selama diperlukan untuk layanan, keamanan, hukum, sengketa, dan siklus cadangan.",
        ),
        LegalSectionContent(
          title: "6. Pilihan dan hak Anda",
          body:
              "Anda dapat mengubah profil, mengelola blokir, menghapus konten yang memenuhi syarat, dan menghapus akun di aplikasi atau halaman penghapusan. Hak akses, koreksi, portabilitas, pembatasan, atau keberatan dapat diminta melalui hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Anak dan transfer internasional",
          body:
              "Layanan tidak ditujukan kepada anak di bawah 13 tahun atau usia persetujuan digital setempat. Data dapat diproses lintas negara dengan perlindungan kontraktual, teknis, dan organisasi.",
        ),
        LegalSectionContent(
          title: "8. Perubahan dan kontak",
          body:
              "Perubahan penting akan diumumkan jika memungkinkan. Hubungi hokhelper@163.com untuk pertanyaan privasi.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Syarat Layanan",
      updated: "Berlaku 31 Juli 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Penerimaan dan kelayakan",
          body:
              "Dengan menggunakan layanan, Anda menerima Syarat dan Kebijakan Privasi serta memenuhi usia minimum setempat.",
        ),
        LegalSectionContent(
          title: "2. Penggunaan yang diperbolehkan",
          body:
              "Dilarang melanggar hukum, mengganggu layanan, menghindari keamanan, menyamar, membuat trafik abusif, curang dalam game langsung, atau melanggar hak pihak lain.",
        ),
        LegalSectionContent(
          title: "3. Konten pengguna",
          body:
              "Anda tetap memiliki konten dan memberi kami lisensi non-eksklusif untuk menghosting, memformat, menerjemahkan, menampilkan, dan mendistribusikannya guna menjalankan layanan. Eksploitasi seksual, ancaman, kebencian, pelecehan, penipuan, konten ilegal, malware, dan disinformasi sengaja dilarang. Kami dapat meninjau laporan, menghapus konten, dan menangguhkan akun.",
        ),
        LegalSectionContent(
          title: "4. Data game, AI, dan pihak ketiga",
          body:
              "Statistik, rekomendasi, terjemahan, dan keluaran AI mungkin tidak akurat dan hanya untuk informasi. HOK Helper tidak berafiliasi resmi dengan TiMi, Tencent, atau Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. Akun dan penghentian",
          body:
              "Anda bertanggung jawab menjaga akun. Anda dapat menghapusnya kapan saja; kami dapat membatasi akses karena pelanggaran, risiko keamanan, hukum, atau penghentian layanan.",
        ),
        LegalSectionContent(
          title: "6. Fitur digital dan pembayaran",
          body:
              "Fitur digital berbayar dalam aplikasi mengikuti aturan pembayaran, refund, dan langganan Apple App Store atau Google Play.",
        ),
        LegalSectionContent(
          title: "7. Ketersediaan dan tanggung jawab",
          body:
              "Layanan tersedia sebagaimana adanya tanpa jaminan akses, kenaikan rank, hasil kompetitif, atau akurasi mutlak.",
        ),
        LegalSectionContent(
          title: "8. Perubahan dan kontak",
          body:
              "Penggunaan berlanjut setelah perubahan berlaku berarti Anda menerimanya. Hubungi hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "Hapus akun HOK Helper dan data terkait",
  ),
  "fil": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Patakaran sa Privacy",
      updated: "Epektibo Hulyo 31, 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Impormasyong kinokolekta",
          body:
              "Kinokolekta namin ang kailangan sa serbisyo: email at profile, Google/Discord/Apple OAuth ID, nilalaman at larawang ina-upload, schemes, interactions, reports/blocks, preferences, session tokens, IP, user-agent, logs, diagnostics, at game ID na kusang ibinibigay. Hindi namin hinihingi ang game password.",
        ),
        LegalSectionContent(
          title: "2. Paggamit ng impormasyon",
          body:
              "Ginagamit ito sa login, sync, regional personalization, seguridad, moderation, support, diagnostics, at pagpapahusay. Hindi namin ibinebenta ang personal data.",
        ),
        LegalSectionContent(
          title: "3. Public content at kaligtasan",
          body:
              "Maaaring makita ng iba at search engines ang public profile at content. Ginagamit ang report at block sa pagtatago at pagsisiyasat ng abuso; maaaring magtanggal ng content o maglimita ng account ang moderators.",
        ),
        LegalSectionContent(
          title: "4. Mga service provider",
          body:
              "Pinoproseso ng Google, Discord, at Apple ang login; ng Cloudflare at infrastructure providers ang traffic, security, logs, at media; ng AI provider ang prompt/larawan kapag ikaw mismo ang gumamit ng AI; at ng app stores ang distribution at billing sa sarili nilang patakaran.",
        ),
        LegalSectionContent(
          title: "5. Storage at retention",
          body:
              "Nasa platform-secure storage ang tokens. Gumagamit kami ng HTTPS, access control, monitoring, at backups. Itinatago lang ang data hangga’t kailangan para sa serbisyo, seguridad, batas, dispute, at backup cycle.",
        ),
        LegalSectionContent(
          title: "6. Mga pagpipilian at karapatan",
          body:
              "Maaari mong ayusin ang profile, pamahalaan ang blocks, alisin ang eligible content, at permanenteng i-delete ang account sa app o deletion page. Para sa access, correction, portability, restriction, o objection, sumulat sa hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Mga bata at international processing",
          body:
              "Hindi para sa batang wala pang 13 o lokal na digital-consent age ang serbisyo. Maaaring iproseso ang data sa ibang bansa na may contractual, technical, at organizational safeguards.",
        ),
        LegalSectionContent(
          title: "8. Pagbabago at contact",
          body:
              "Ipaaalam ang mahahalagang pagbabago kung praktikal. Para sa privacy, kontakin ang hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Mga Tuntunin ng Serbisyo",
      updated: "Epektibo Hulyo 31, 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Pagtanggap at eligibility",
          body:
              "Sa paggamit, tinatanggap mo ang Terms at Privacy Policy at natutugunan mo ang minimum age sa iyong bansa.",
        ),
        LegalSectionContent(
          title: "2. Tamang paggamit",
          body:
              "Bawal ang ilegal na gamit, pag-abala sa serbisyo, pag-iwas sa seguridad, pagpapanggap, abusive automation, pandaraya sa live games, at paglabag sa karapatan ng iba.",
        ),
        LegalSectionContent(
          title: "3. User content",
          body:
              "Pag-aari mo pa rin ang content at binibigyan mo kami ng non-exclusive license na i-host, i-format, isalin, ipakita, at ipamahagi para mapatakbo ang serbisyo. Bawal ang sexual exploitation, threats, hate, harassment, scams, illegal content, malware, at sinadyang misinformation. Maaari kaming mag-review, magtanggal, at magsuspinde.",
        ),
        LegalSectionContent(
          title: "4. Game data, AI, at third parties",
          body:
              "Maaaring hindi kumpleto ang stats, recommendations, translations, at AI output at para sa impormasyon lamang. Hindi opisyal na kaakibat ng TiMi, Tencent, o Level Infinite ang HOK Helper.",
        ),
        LegalSectionContent(
          title: "5. Account at termination",
          body:
              "Responsibilidad mong protektahan ang account. Maaari mo itong i-delete; maaari naming limitahan dahil sa violation, security, batas, o pagsara ng serbisyo.",
        ),
        LegalSectionContent(
          title: "6. Digital features at billing",
          body:
              "Ang bayad na digital features sa mobile ay susunod sa Apple App Store o Google Play billing, refund, at subscription rules.",
        ),
        LegalSectionContent(
          title: "7. Availability at liability",
          body:
              "Ibinibigay ang serbisyo as available, nang walang garantiya sa access, rank, competitive result, o ganap na accuracy.",
        ),
        LegalSectionContent(
          title: "8. Pagbabago at contact",
          body:
              "Ang patuloy na paggamit pagkatapos ng pagbabago ay pagtanggap dito. Kontakin ang hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "I-delete ang HOK Helper account at kaugnay na data",
  ),
  "pt": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Política de Privacidade",
      updated: "Em vigor em 31 de julho de 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Informações coletadas",
          body:
              "Coletamos o necessário para o serviço: e-mail e perfil, IDs OAuth do Google/Discord/Apple, conteúdo e imagens enviados, esquemas, interações, denúncias/bloqueios, preferências, tokens, IP, agente do usuário, logs, diagnósticos e identificadores de jogo fornecidos voluntariamente. Não solicitamos sua senha do jogo.",
        ),
        LegalSectionContent(
          title: "2. Como usamos",
          body:
              "Usamos os dados para autenticação, sincronização, personalização regional, segurança, moderação, suporte, diagnóstico e melhorias. Não vendemos dados pessoais.",
        ),
        LegalSectionContent(
          title: "3. Conteúdo público e segurança",
          body:
              "Perfis e conteúdos públicos podem ser vistos por usuários e buscadores. Denúncias e bloqueios ajudam a ocultar e investigar abusos; moderadores podem remover conteúdo ou restringir contas.",
        ),
        LegalSectionContent(
          title: "4. Prestadores de serviço",
          body:
              "Google, Discord e Apple processam login; Cloudflare e infraestrutura processam tráfego, segurança, logs e mídia; provedores de IA recebem prompts/imagens somente quando a função é acionada; lojas processam distribuição e cobrança sob suas políticas.",
        ),
        LegalSectionContent(
          title: "5. Armazenamento e retenção",
          body:
              "Tokens ficam no armazenamento seguro da plataforma. Usamos HTTPS, controles, monitoramento e backups. Mantemos dados apenas pelo tempo necessário ao serviço, segurança, lei, disputas e ciclo de backup.",
        ),
        LegalSectionContent(
          title: "6. Suas escolhas e direitos",
          body:
              "Você pode editar o perfil, gerenciar bloqueios, remover conteúdo elegível e excluir permanentemente a conta no app ou na página de exclusão. Solicitações de acesso, correção, portabilidade, restrição ou oposição: hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Crianças e transferências",
          body:
              "O serviço não se destina a menores de 13 anos ou da idade local de consentimento digital. Dados podem ser processados em outros países com salvaguardas contratuais, técnicas e organizacionais.",
        ),
        LegalSectionContent(
          title: "8. Alterações e contato",
          body:
              "Mudanças relevantes serão comunicadas quando possível. Contato de privacidade: hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Termos de Serviço",
      updated: "Em vigor em 31 de julho de 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Aceitação e elegibilidade",
          body:
              "Ao usar o serviço, você aceita estes Termos e a Política e deve cumprir a idade mínima local.",
        ),
        LegalSectionContent(
          title: "2. Uso aceitável",
          body:
              "É proibido uso ilegal, interferência, evasão de segurança, falsidade de identidade, tráfego abusivo, trapaça em partidas ao vivo ou violação de direitos.",
        ),
        LegalSectionContent(
          title: "3. Conteúdo do usuário",
          body:
              "Você mantém a propriedade e concede licença não exclusiva para hospedar, formatar, traduzir, exibir e distribuir o conteúdo para operar o serviço. Exploração sexual, ameaças, ódio, assédio, golpes, conteúdo ilegal, malware e desinformação deliberada são proibidos. Podemos revisar, remover e suspender.",
        ),
        LegalSectionContent(
          title: "4. Dados do jogo, IA e terceiros",
          body:
              "Estatísticas, recomendações, traduções e IA podem conter erros e são informativas. HOK Helper não é afiliado oficialmente à TiMi, Tencent ou Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. Contas e encerramento",
          body:
              "Proteja sua conta. Você pode excluí-la; podemos restringir acesso por violações, segurança, lei ou encerramento do serviço.",
        ),
        LegalSectionContent(
          title: "6. Recursos digitais e cobrança",
          body:
              "Recursos digitais pagos no app seguem as regras de cobrança, reembolso e assinatura da Apple App Store ou Google Play.",
        ),
        LegalSectionContent(
          title: "7. Disponibilidade e responsabilidade",
          body:
              "O serviço é fornecido conforme disponível, sem garantia de acesso, evolução de ranking, resultados ou precisão absoluta.",
        ),
        LegalSectionContent(
          title: "8. Alterações e contato",
          body:
              "O uso contínuo após a vigência das alterações significa aceitação. Contato: hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "Excluir sua conta HOK Helper e os dados associados",
  ),
  "es": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Política de Privacidad",
      updated: "Vigente desde el 31 de julio de 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Información recopilada",
          body:
              "Recopilamos lo necesario para operar: correo y perfil, identificadores OAuth de Google/Discord/Apple, contenido e imágenes subidos, esquemas, interacciones, denuncias/bloqueos, preferencias, tokens, IP, agente de usuario, registros, diagnósticos e identificadores del juego proporcionados voluntariamente. No pedimos la contraseña del juego.",
        ),
        LegalSectionContent(
          title: "2. Cómo la utilizamos",
          body:
              "La usamos para autenticación, sincronización, personalización regional, seguridad, moderación, soporte, diagnóstico y mejora. No vendemos datos personales.",
        ),
        LegalSectionContent(
          title: "3. Contenido público y seguridad",
          body:
              "Los perfiles y contenidos públicos pueden ser visibles para usuarios y buscadores. Las denuncias y bloqueos sirven para ocultar e investigar abusos; los moderadores pueden retirar contenido o restringir cuentas.",
        ),
        LegalSectionContent(
          title: "4. Proveedores",
          body:
              "Google, Discord y Apple procesan el inicio de sesión; Cloudflare e infraestructura procesan tráfico, seguridad, registros y medios; proveedores de IA reciben indicaciones/imágenes solo cuando activas la función; las tiendas procesan distribución y cobro según sus políticas.",
        ),
        LegalSectionContent(
          title: "5. Almacenamiento y conservación",
          body:
              "Los tokens usan el almacenamiento seguro de la plataforma. Aplicamos HTTPS, controles, supervisión y copias. Conservamos datos solo durante lo necesario para servicio, seguridad, ley, disputas y copias de seguridad.",
        ),
        LegalSectionContent(
          title: "6. Tus opciones y derechos",
          body:
              "Puedes editar el perfil, gestionar bloqueos, retirar contenido apto y eliminar la cuenta en la app o la página de eliminación. Para acceso, corrección, portabilidad, limitación u oposición: hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Menores y transferencias",
          body:
              "El servicio no está dirigido a menores de 13 años ni por debajo de la edad local de consentimiento digital. Los datos pueden tratarse internacionalmente con garantías contractuales, técnicas y organizativas.",
        ),
        LegalSectionContent(
          title: "8. Cambios y contacto",
          body:
              "Avisaremos cambios importantes cuando sea posible. Contacto de privacidad: hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Términos del Servicio",
      updated: "Vigente desde el 31 de julio de 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Aceptación y elegibilidad",
          body:
              "Al usar el servicio aceptas estos Términos y la Política y debes cumplir la edad mínima local.",
        ),
        LegalSectionContent(
          title: "2. Uso aceptable",
          body:
              "Se prohíbe el uso ilegal, interferir, eludir seguridad, suplantar, automatizar abuso, hacer trampas en partidas en vivo o vulnerar derechos.",
        ),
        LegalSectionContent(
          title: "3. Contenido del usuario",
          body:
              "Conservas la propiedad y otorgas una licencia no exclusiva para alojar, formatear, traducir, mostrar y distribuir el contenido al operar el servicio. Se prohíben explotación sexual, amenazas, odio, acoso, fraude, contenido ilegal, malware y desinformación deliberada. Podemos revisar, retirar y suspender.",
        ),
        LegalSectionContent(
          title: "4. Datos del juego, IA y terceros",
          body:
              "Las estadísticas, recomendaciones, traducciones y resultados de IA pueden ser inexactos y son informativos. HOK Helper no está afiliado oficialmente con TiMi, Tencent ni Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. Cuentas y terminación",
          body:
              "Protege tu cuenta. Puedes eliminarla; podemos limitar el acceso por infracciones, seguridad, ley o cierre del servicio.",
        ),
        LegalSectionContent(
          title: "6. Funciones digitales y cobro",
          body:
              "Las funciones digitales de pago en móvil siguen las reglas de cobro, reembolso y suscripción de Apple App Store o Google Play.",
        ),
        LegalSectionContent(
          title: "7. Disponibilidad y responsabilidad",
          body:
              "El servicio se ofrece según disponibilidad, sin garantizar acceso, mejora de rango, resultados o exactitud absoluta.",
        ),
        LegalSectionContent(
          title: "8. Cambios y contacto",
          body:
              "El uso continuado tras la entrada en vigor supone aceptación. Contacto: hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink:
        "Eliminar tu cuenta de HOK Helper y los datos asociados",
  ),
  "ar": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "سياسة الخصوصية",
      updated: "تسري اعتبارًا من 31 يوليو 2026.",
      sections: [
        LegalSectionContent(
          title: "1. المعلومات التي نجمعها",
          body:
              "نجمع ما يلزم لتشغيل الخدمة: البريد والملف الشخصي، معرّفات OAuth من Google وDiscord وApple، المحتوى والصور والخطط والتفاعلات والبلاغات والحظر والتفضيلات والرموز وعنوان IP وسجل الطلبات والتشخيص ومعرّفات اللعبة المقدمة طوعًا. لا نطلب كلمة مرور اللعبة.",
        ),
        LegalSectionContent(
          title: "2. كيفية الاستخدام",
          body:
              "نستخدم البيانات للمصادقة والمزامنة والتخصيص والأمان والإشراف والدعم والتشخيص والتحسين. لا نبيع البيانات الشخصية.",
        ),
        LegalSectionContent(
          title: "3. المحتوى العام والسلامة",
          body:
              "قد تظهر الملفات والمحتويات العامة للمستخدمين ومحركات البحث. تساعد البلاغات والحظر على إخفاء الإساءة والتحقيق فيها، ويجوز للمشرفين إزالة المحتوى أو تقييد الحسابات.",
        ),
        LegalSectionContent(
          title: "4. مزودو الخدمة",
          body:
              "تعالج Google وDiscord وApple تسجيل الدخول؛ وتعالج Cloudflare والبنية التحتية حركة الشبكة والأمان والسجلات والوسائط؛ ويعالج مزود الذكاء الاصطناعي المدخلات فقط عند تشغيل الميزة؛ وتعالج المتاجر التوزيع والدفع وفق سياساتها.",
        ),
        LegalSectionContent(
          title: "5. التخزين والاحتفاظ",
          body:
              "تُحفظ الرموز في تخزين المنصة الآمن. نستخدم HTTPS وضوابط وصول ومراقبة ونسخًا احتياطية. نحتفظ بالبيانات فقط للمدة اللازمة للخدمة والأمان والقانون والنزاعات ودورة النسخ.",
        ),
        LegalSectionContent(
          title: "6. خياراتك وحقوقك",
          body:
              "يمكنك تعديل الملف وإدارة الحظر وحذف المحتوى المؤهل وحذف الحساب نهائيًا من التطبيق أو صفحة الحذف. لطلبات الوصول أو التصحيح أو النقل أو التقييد أو الاعتراض: hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. الأطفال والنقل الدولي",
          body:
              "الخدمة غير موجهة لمن هم دون 13 عامًا أو سن الموافقة الرقمية المحلي. قد تعالج البيانات في دول أخرى مع ضمانات تعاقدية وتقنية وتنظيمية.",
        ),
        LegalSectionContent(
          title: "8. التغييرات والتواصل",
          body:
              "سنعلن التغييرات المهمة حيثما أمكن. تواصل الخصوصية: hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "شروط الخدمة",
      updated: "تسري اعتبارًا من 31 يوليو 2026.",
      sections: [
        LegalSectionContent(
          title: "1. القبول والأهلية",
          body:
              "باستخدام الخدمة توافق على الشروط والسياسة ويجب أن تستوفي الحد الأدنى للعمر في بلدك.",
        ),
        LegalSectionContent(
          title: "2. الاستخدام المقبول",
          body:
              "يحظر الاستخدام غير القانوني أو تعطيل الخدمة أو تجاوز الأمان أو الانتحال أو الحركة المسيئة أو الغش في المباريات الحية أو انتهاك الحقوق.",
        ),
        LegalSectionContent(
          title: "3. محتوى المستخدم",
          body:
              "تحتفظ بالملكية وتمنحنا ترخيصًا غير حصري للاستضافة والتنسيق والترجمة والعرض والتوزيع لتشغيل الخدمة. يحظر الاستغلال الجنسي والتهديد والكراهية والتحرش والاحتيال والمحتوى غير القانوني والبرمجيات الخبيثة والتضليل المتعمد. يجوز لنا المراجعة والإزالة والتعليق.",
        ),
        LegalSectionContent(
          title: "4. بيانات اللعبة والذكاء الاصطناعي",
          body:
              "قد تكون الإحصاءات والتوصيات والترجمات ونتائج الذكاء الاصطناعي غير دقيقة وللمعلومات فقط. HOK Helper غير تابع رسميًا لـ TiMi أو Tencent أو Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. الحساب والإنهاء",
          body:
              "احم حسابك. يمكنك حذفه، ويمكننا تقييد الوصول للمخالفات أو الأمان أو القانون أو إيقاف الخدمة.",
        ),
        LegalSectionContent(
          title: "6. الميزات الرقمية والدفع",
          body:
              "تخضع الميزات الرقمية المدفوعة لقواعد الدفع والاسترداد والاشتراك في Apple App Store أو Google Play.",
        ),
        LegalSectionContent(
          title: "7. التوفر والمسؤولية",
          body:
              "تقدم الخدمة حسب التوفر دون ضمان الوصول أو تحسن التصنيف أو النتائج أو الدقة المطلقة.",
        ),
        LegalSectionContent(
          title: "8. التغييرات والتواصل",
          body:
              "استمرار الاستخدام بعد سريان التغييرات يعني قبولها. التواصل: hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "حذف حساب HOK Helper والبيانات المرتبطة به",
  ),
  "ru": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Политика конфиденциальности",
      updated: "Действует с 31 июля 2026 г.",
      sections: [
        LegalSectionContent(
          title: "1. Какие данные мы собираем",
          body:
              "Мы собираем необходимое для сервиса: email и профиль, OAuth-ID Google/Discord/Apple, загруженный контент и изображения, схемы, действия, жалобы/блокировки, настройки, токены, IP, user-agent, журналы, диагностику и добровольно указанные игровые ID. Пароль от игры не запрашивается.",
        ),
        LegalSectionContent(
          title: "2. Как используются данные",
          body:
              "Для входа, синхронизации, региональной персонализации, безопасности, модерации, поддержки, диагностики и улучшения. Мы не продаем персональные данные.",
        ),
        LegalSectionContent(
          title: "3. Публичный контент и безопасность",
          body:
              "Публичные профили и материалы могут видеть пользователи и поисковые системы. Жалобы и блокировки помогают скрывать и расследовать нарушения; модераторы могут удалить контент или ограничить аккаунт.",
        ),
        LegalSectionContent(
          title: "4. Поставщики услуг",
          body:
              "Google, Discord и Apple обрабатывают вход; Cloudflare и инфраструктура — трафик, безопасность, журналы и медиа; ИИ-провайдер получает запросы/изображения только при запуске функции; магазины обрабатывают распространение и платежи по своим правилам.",
        ),
        LegalSectionContent(
          title: "5. Хранение и сроки",
          body:
              "Токены хранятся в защищенном хранилище платформы. Используются HTTPS, контроль доступа, мониторинг и резервные копии. Данные сохраняются только для сервиса, безопасности, закона, споров и цикла резервного копирования.",
        ),
        LegalSectionContent(
          title: "6. Ваши права",
          body:
              "Можно менять профиль, управлять блокировками, удалять допустимый контент и аккаунт в приложении или на странице удаления. Запросы доступа, исправления, переноса, ограничения или возражения: hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Дети и международная обработка",
          body:
              "Сервис не предназначен для лиц младше 13 лет или местного возраста цифрового согласия. Данные могут обрабатываться в других странах с договорными, техническими и организационными гарантиями.",
        ),
        LegalSectionContent(
          title: "8. Изменения и контакты",
          body:
              "О существенных изменениях сообщается, когда это возможно. Контакт по приватности: hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Условия использования",
      updated: "Действует с 31 июля 2026 г.",
      sections: [
        LegalSectionContent(
          title: "1. Принятие и возраст",
          body:
              "Используя сервис, вы принимаете Условия и Политику и должны соответствовать местному минимальному возрасту.",
        ),
        LegalSectionContent(
          title: "2. Допустимое использование",
          body:
              "Запрещены незаконные действия, помехи сервису, обход защиты, выдача себя за другого, вредная автоматизация, читы в текущих матчах и нарушение прав.",
        ),
        LegalSectionContent(
          title: "3. Пользовательский контент",
          body:
              "Вы сохраняете права и даете неисключительную лицензию на размещение, форматирование, перевод, показ и распространение для работы сервиса. Запрещены сексуальная эксплуатация, угрозы, ненависть, травля, мошенничество, незаконный контент, вредоносное ПО и сознательная дезинформация. Мы можем проверять, удалять и блокировать.",
        ),
        LegalSectionContent(
          title: "4. Игровые данные, ИИ и третьи лица",
          body:
              "Статистика, рекомендации, переводы и ИИ могут ошибаться и носят информационный характер. HOK Helper официально не связан с TiMi, Tencent или Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. Аккаунт и прекращение",
          body:
              "Защищайте аккаунт. Его можно удалить; доступ может быть ограничен из-за нарушений, безопасности, закона или закрытия сервиса.",
        ),
        LegalSectionContent(
          title: "6. Цифровые функции и платежи",
          body:
              "Платные цифровые функции подчиняются правилам оплаты, возврата и подписок Apple App Store или Google Play.",
        ),
        LegalSectionContent(
          title: "7. Доступность и ответственность",
          body:
              "Сервис предоставляется по мере доступности без гарантий доступа, роста рейтинга, результатов или абсолютной точности.",
        ),
        LegalSectionContent(
          title: "8. Изменения и контакты",
          body:
              "Продолжение использования после вступления изменений в силу означает согласие. Контакт: hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "Удалить аккаунт HOK Helper и связанные данные",
  ),
  "ms": LegalCopyContent(
    privacy: LegalDocumentContent(
      title: "Dasar Privasi",
      updated: "Berkuat kuasa 31 Julai 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Maklumat yang dikumpul",
          body:
              "Kami mengumpul yang diperlukan: e-mel dan profil, ID OAuth Google/Discord/Apple, kandungan dan imej dimuat naik, skim, interaksi, laporan/sekat, pilihan, token, IP, user-agent, log, diagnostik dan ID permainan yang diberi secara sukarela. Kami tidak meminta kata laluan permainan.",
        ),
        LegalSectionContent(
          title: "2. Cara kami menggunakan data",
          body:
              "Untuk pengesahan, penyegerakan, pemperibadian rantau, keselamatan, moderasi, sokongan, diagnostik dan penambahbaikan. Kami tidak menjual data peribadi.",
        ),
        LegalSectionContent(
          title: "3. Kandungan awam dan keselamatan",
          body:
              "Profil dan kandungan awam boleh dilihat pengguna atau enjin carian. Laporan dan sekatan membantu menyembunyi serta menyiasat penyalahgunaan; moderator boleh membuang kandungan atau mengehadkan akaun.",
        ),
        LegalSectionContent(
          title: "4. Penyedia perkhidmatan",
          body:
              "Google, Discord dan Apple memproses log masuk; Cloudflare dan infrastruktur memproses trafik, keselamatan, log dan media; penyedia AI menerima prompt/imej hanya apabila fungsi digunakan; gedung aplikasi memproses pengedaran dan bayaran mengikut dasar mereka.",
        ),
        LegalSectionContent(
          title: "5. Penyimpanan dan pengekalan",
          body:
              "Token disimpan dalam storan selamat platform. Kami menggunakan HTTPS, kawalan akses, pemantauan dan sandaran. Data disimpan hanya selama perlu untuk perkhidmatan, keselamatan, undang-undang, pertikaian dan kitaran sandaran.",
        ),
        LegalSectionContent(
          title: "6. Pilihan dan hak anda",
          body:
              "Anda boleh mengubah profil, mengurus sekatan, memadam kandungan layak dan akaun melalui aplikasi atau halaman pemadaman. Permintaan akses, pembetulan, mudah alih, sekatan atau bantahan: hokhelper@163.com.",
        ),
        LegalSectionContent(
          title: "7. Kanak-kanak dan pemprosesan antarabangsa",
          body:
              "Perkhidmatan bukan untuk kanak-kanak bawah 13 tahun atau umur persetujuan digital tempatan. Data mungkin diproses di negara lain dengan perlindungan kontrak, teknikal dan organisasi.",
        ),
        LegalSectionContent(
          title: "8. Perubahan dan hubungan",
          body:
              "Perubahan penting akan diumumkan apabila praktikal. Hubungan privasi: hokhelper@163.com.",
        ),
      ],
    ),
    terms: LegalDocumentContent(
      title: "Terma Perkhidmatan",
      updated: "Berkuat kuasa 31 Julai 2026.",
      sections: [
        LegalSectionContent(
          title: "1. Penerimaan dan kelayakan",
          body:
              "Dengan menggunakan perkhidmatan, anda menerima Terma dan Dasar serta memenuhi umur minimum tempatan.",
        ),
        LegalSectionContent(
          title: "2. Penggunaan diterima",
          body:
              "Dilarang penggunaan haram, mengganggu perkhidmatan, memintas keselamatan, menyamar, automasi kesat, menipu dalam permainan langsung atau melanggar hak.",
        ),
        LegalSectionContent(
          title: "3. Kandungan pengguna",
          body:
              "Anda mengekalkan pemilikan dan memberi lesen bukan eksklusif untuk hos, format, terjemah, papar dan edar bagi operasi perkhidmatan. Eksploitasi seksual, ancaman, kebencian, gangguan, penipuan, kandungan haram, perisian hasad dan maklumat palsu sengaja dilarang. Kami boleh menyemak, membuang dan menggantung.",
        ),
        LegalSectionContent(
          title: "4. Data permainan, AI dan pihak ketiga",
          body:
              "Statistik, cadangan, terjemahan dan output AI mungkin tidak tepat dan hanya untuk maklumat. HOK Helper tidak bersekutu rasmi dengan TiMi, Tencent atau Level Infinite.",
        ),
        LegalSectionContent(
          title: "5. Akaun dan penamatan",
          body:
              "Lindungi akaun anda. Anda boleh memadamnya; kami boleh mengehadkan akses kerana pelanggaran, keselamatan, undang-undang atau penamatan perkhidmatan.",
        ),
        LegalSectionContent(
          title: "6. Ciri digital dan bayaran",
          body:
              "Ciri digital berbayar dalam aplikasi mengikut peraturan bayaran, bayaran balik dan langganan Apple App Store atau Google Play.",
        ),
        LegalSectionContent(
          title: "7. Ketersediaan dan liabiliti",
          body:
              "Perkhidmatan diberi mengikut ketersediaan tanpa jaminan akses, kenaikan rank, hasil atau ketepatan mutlak.",
        ),
        LegalSectionContent(
          title: "8. Perubahan dan hubungan",
          body:
              "Penggunaan berterusan selepas perubahan berkuat kuasa bermakna penerimaan. Hubungi hokhelper@163.com.",
        ),
      ],
    ),
    accountDeletionLink: "Padam akaun HOK Helper dan data berkaitan",
  ),
};
