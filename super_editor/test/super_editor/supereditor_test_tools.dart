import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';
import 'package:text_table/text_table.dart';

import '../test_tools_user_input.dart';
import 'test_documents.dart';

/// Extensions on [WidgetTester] that configure and pump [SuperEditor]
/// document editors.
extension DocumentTester on WidgetTester {
  /// Starts the process for configuring and pumping a new [SuperEditor].
  ///
  /// Use the returned [TestDocumentSelector] to continue configuring the
  /// [SuperEditor].
  TestDocumentSelector createDocument() {
    return TestDocumentSelector(this);
  }

  /// Pumps a new [SuperEditor] using an existing [configuration].
  ///
  /// Use this method to simulate a [SuperEditor] whose widget tree changes.
  TestSuperEditorConfigurator updateDocument(SuperEditorTestConfiguration configuration) {
    return TestSuperEditorConfigurator._fromExistingConfiguration(this, configuration);
  }
}

/// Selects a [Document] configuration when composing a [SuperEditor]
/// widget in a test.
///
/// Each document selection returns a [TestSuperEditorConfigurator], which
/// is used to complete the configuration, and to pump the [SuperEditor].
class TestDocumentSelector {
  const TestDocumentSelector(this._widgetTester);

  final WidgetTester _widgetTester;

  TestSuperEditorConfigurator withCustomContent(MutableDocument document) {
    return TestSuperEditorConfigurator._(_widgetTester, document);
  }

  /// Configures the editor with a [Document] that's parsed from the
  /// given [markdown].
  TestSuperEditorConfigurator fromMarkdown(String markdown) {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      deserializeMarkdownToDocument(markdown),
    );
  }

  TestSuperEditorConfigurator withSingleEmptyParagraph() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      singleParagraphEmptyDoc(),
    );
  }

  TestSuperEditorConfigurator withSingleParagraph() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      singleParagraphDoc(),
    );
  }

  TestSuperEditorConfigurator withSingleParagraphAndLink() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      singleParagraphWithLinkDoc(),
    );
  }

  TestSuperEditorConfigurator withTwoEmptyParagraphs() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      twoParagraphEmptyDoc(),
    );
  }

  TestSuperEditorConfigurator withLongTextContent() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      longTextDoc(),
    );
  }

  TestSuperEditorConfigurator withLongDoc() {
    return TestSuperEditorConfigurator._(
      _widgetTester,
      longDoc(),
    );
  }
}

/// Builder that configures and pumps a [SuperEditor] widget.
class TestSuperEditorConfigurator {
  TestSuperEditorConfigurator._fromExistingConfiguration(this._widgetTester, this._config);

  TestSuperEditorConfigurator._(this._widgetTester, MutableDocument document)
      : _config = SuperEditorTestConfiguration(document);

  final WidgetTester _widgetTester;
  final SuperEditorTestConfiguration _config;

  TestSuperEditorConfigurator withAddedRequestHandlers(List<EditRequestHandler> addedRequestHandlers) {
    _config.addedRequestHandlers.addAll(addedRequestHandlers);
    return this;
  }

  TestSuperEditorConfigurator withAddedReactions(List<EditReaction> addedReactions) {
    _config.addedReactions.addAll(addedReactions);
    return this;
  }

  /// Configures the [SuperEditor] for standard desktop interactions,
  /// e.g., mouse and keyboard input.
  TestSuperEditorConfigurator forDesktop({
    TextInputSource inputSource = TextInputSource.ime,
  }) {
    _config.inputSource = inputSource;
    _config.gestureMode = DocumentGestureMode.mouse;
    return this;
  }

  /// Configures the [SuperEditor] for standard Android interactions,
  /// e.g., touch gestures and IME input.
  TestSuperEditorConfigurator forAndroid() {
    _config.gestureMode = DocumentGestureMode.android;
    _config.inputSource = TextInputSource.ime;
    return this;
  }

  /// Configures the [SuperEditor] for standard iOS interactions,
  /// e.g., touch gestures and IME input.
  TestSuperEditorConfigurator forIOS() {
    _config.gestureMode = DocumentGestureMode.iOS;
    _config.inputSource = TextInputSource.ime;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [inputSource].
  TestSuperEditorConfigurator withInputSource(TextInputSource inputSource) {
    _config.inputSource = inputSource;
    return this;
  }

  /// Configures the [SuperEditor] with the given selection [policies], which dictate the interactions
  /// between selection and other details, such as focus change.
  TestSuperEditorConfigurator withSelectionPolicies(SuperEditorSelectionPolicies policies) {
    _config.selectionPolicies = policies;
    return this;
  }

  /// Configures the [SuperEditor] with the given selection [styles], which dictate the color of the
  /// primary user's selection, and related selection details.
  TestSuperEditorConfigurator withSelectionStyles(SelectionStyles? styles) {
    _config.selectionStyles = styles;
    return this;
  }

  TestSuperEditorConfigurator withCaretPolicies({
    bool? displayCaretWithExpandedSelection,
  }) {
    if (displayCaretWithExpandedSelection != null) {
      _config.displayCaretWithExpandedSelection = displayCaretWithExpandedSelection;
    }
    return this;
  }

  TestSuperEditorConfigurator withCaretStyle({CaretStyle? caretStyle}) {
    _config.caretStyle = caretStyle;
    return this;
  }

  /// Configures the [SuperEditor]'s [SoftwareKeyboardController].
  TestSuperEditorConfigurator withSoftwareKeyboardController(SoftwareKeyboardController controller) {
    _config.softwareKeyboardController = controller;
    return this;
  }

  /// Configures the [SuperEditor] with the given IME [policies], which dictate the interactions
  /// between focus, selection, and the platform IME, including software keyborads on mobile.
  TestSuperEditorConfigurator withImePolicies(SuperEditorImePolicies policies) {
    _config.imePolicies = policies;
    return this;
  }

  /// Configures the way in which the user interacts with the IME, e.g., brightness, autocorrection, etc.
  TestSuperEditorConfigurator withImeConfiguration(SuperEditorImeConfiguration configuration) {
    _config.imeConfiguration = configuration;
    return this;
  }

  /// Configures the [SuperEditor] to intercept and override desired IME signals, as
  /// determined by the given [imeOverrides].
  TestSuperEditorConfigurator withImeOverrides(DeltaTextInputClientDecorator imeOverrides) {
    _config.imeOverrides = imeOverrides;
    return this;
  }

  TestSuperEditorConfigurator withAddedKeyboardActions({
    List<DocumentKeyboardAction> prepend = const [],
    List<DocumentKeyboardAction> append = const [],
  }) {
    _config.prependedKeyboardActions.addAll(prepend);
    _config.appendedKeyboardActions.addAll(append);
    return this;
  }

  /// Configures the [SuperEditor] to use the given selector [handlers].
  TestSuperEditorConfigurator withSelectorHandlers(Map<String, SuperEditorSelectorHandler> handlers) {
    _config.selectorHandlers = handlers;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [gestureMode].
  TestSuperEditorConfigurator withGestureMode(DocumentGestureMode gestureMode) {
    _config.gestureMode = gestureMode;
    return this;
  }

  /// Configures the [SuperEditor] to constrain its maxHeight and maxWidth using the given [size].
  TestSuperEditorConfigurator withEditorSize(ui.Size? size) {
    _config.editorSize = size;
    return this;
  }

  /// Configures the [SuperEditor] to use only the given [componentBuilders]
  TestSuperEditorConfigurator withComponentBuilders(List<ComponentBuilder>? componentBuilders) {
    _config.componentBuilders = componentBuilders;
    return this;
  }

  /// Configures the [SuperEditor] to use a custom widget tree above [SuperEditor].
  TestSuperEditorConfigurator withCustomWidgetTreeBuilder(WidgetTreeBuilder? builder) {
    _config.widgetTreeBuilder = builder;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [scrollController]
  TestSuperEditorConfigurator withScrollController(ScrollController? scrollController) {
    _config.scrollController = scrollController;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [focusNode]
  TestSuperEditorConfigurator withFocusNode(FocusNode? focusNode) {
    _config.focusNode = focusNode;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [selection] as its initial selection.
  TestSuperEditorConfigurator withSelection(DocumentSelection? selection) {
    _config.selection = selection;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [builder] as its android toolbar builder.
  TestSuperEditorConfigurator withAndroidToolbarBuilder(DocumentFloatingToolbarBuilder? builder) {
    _config.androidToolbarBuilder = builder;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [builder] as its iOS toolbar builder.
  TestSuperEditorConfigurator withiOSToolbarBuilder(DocumentFloatingToolbarBuilder? builder) {
    _config.iOSToolbarBuilder = builder;
    return this;
  }

  /// Configures the [ThemeData] used for the [MaterialApp] that wraps
  /// the [SuperEditor].
  TestSuperEditorConfigurator useAppTheme(ThemeData theme) {
    _config.appTheme = theme;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [stylesheet].
  TestSuperEditorConfigurator useStylesheet(Stylesheet? stylesheet) {
    _config.stylesheet = stylesheet;
    return this;
  }

  /// Adds the given component builders to the list of component builders that are
  /// used to render the document layout in the pumped [SuperEditor].
  TestSuperEditorConfigurator withAddedComponents(List<ComponentBuilder> newComponents) {
    _config.addedComponents.addAll(newComponents);
    return this;
  }

  /// Configures the [SuperEditor] to auto-focus when first pumped, or not.
  TestSuperEditorConfigurator autoFocus(bool autoFocus) {
    _config.autoFocus = autoFocus;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [key].
  TestSuperEditorConfigurator withKey(Key? key) {
    _config.key = key;
    return this;
  }

  /// Configures the [SuperEditor] [DocumentLayout] to use the given [layoutKey].
  TestSuperEditorConfigurator withLayoutKey(GlobalKey? layoutKey) {
    _config.layoutKey = layoutKey;
    return this;
  }

  /// Applies the given [plugin] to the pumped [SuperEditor].
  TestSuperEditorConfigurator withPlugin(SuperEditorPlugin plugin) {
    _config.plugins.add(plugin);
    return this;
  }

  /// Configures the [SuperEditor] to be displayed inside a [CustomScrollView].
  ///
  /// The [CustomScrollView] is constrained by the size provided in [withEditorSize].
  ///
  /// Use [withScrollController] to define the [ScrollController] of the [CustomScrollView].
  TestSuperEditorConfigurator insideCustomScrollView() {
    _config.insideCustomScrollView = true;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [tapRegionGroupId].
  ///
  /// This DOESN'T wrap the editor with a [TapRegion].
  TestSuperEditorConfigurator withTapRegionGroupId(String? tapRegionGroupId) {
    _config.tapRegionGroupId = tapRegionGroupId;
    return this;
  }

  /// Pumps a [SuperEditor] widget tree with the desired configuration, and returns
  /// a [TestDocumentContext], which includes the artifacts connected to the widget
  /// tree, e.g., the [DocumentEditor], [DocumentComposer], etc.
  ///
  /// If you need access to the pumped [Widget], use [build] instead of this method,
  /// and then call [WidgetTester.pump] with the returned [Widget].
  Future<TestDocumentContext> pump() async {
    final testDocumentContext = _createTestDocumentContext();
    await _widgetTester.pumpWidget(
      _build(testDocumentContext).widget,
    );
    return testDocumentContext;
  }

  /// Builds a Super Editor experience based on chosen configurations and
  /// returns a [ConfiguredSuperEditorWidget], which includes the associated
  /// Super Editor [Widget].
  ///
  /// If you want to immediately pump this UI into a [WidgetTester], use
  /// [pump], which does that for you.
  ConfiguredSuperEditorWidget build() {
    return _build();
  }

  /// Builds a [SuperEditor] widget tree based on the configuration in this
  /// class and the (optional) [TestDocumentContext].
  ///
  /// If no [TestDocumentContext] is provided, one will be created based on the current
  /// configuration of this class.
  ConfiguredSuperEditorWidget _build([TestDocumentContext? testDocumentContext]) {
    final context = testDocumentContext ?? _createTestDocumentContext();
    final superEditor = _buildConstrainedContent(
      _buildAncestorScrollable(
        child: _buildSuperEditor(context),
      ),
    );

    return ConfiguredSuperEditorWidget(
      context,
      _buildWidgetTree(superEditor),
    );
  }

  /// Creates a [TestDocumentContext] based on the configurations in this class.
  ///
  /// A [TestDocumentContext] is useful as a return value for clients, so that
  /// those clients can access important pieces within a [SuperEditor] widget.
  TestDocumentContext _createTestDocumentContext() {
    // Only assign if non-null in case we're updating an existing configuration
    // from a previous widget pump.
    _config.layoutKey ??= GlobalKey();

    final layoutKey = _config.layoutKey!;
    final focusNode = _config.focusNode ?? FocusNode();
    final composer = MutableDocumentComposer(initialSelection: _config.selection);
    final editor = createDefaultDocumentEditor(document: _config.document, composer: composer)
      ..requestHandlers.insertAll(0, _config.addedRequestHandlers)
      ..reactionPipeline.insertAll(0, _config.addedReactions);

    return TestDocumentContext._(
      focusNode: focusNode,
      layoutKey: layoutKey,
      document: _config.document,
      composer: composer,
      editor: editor,
      configuration: _config,
    );
  }

  /// Builds a complete screen experience, which includes the given [superEditor].
  Widget _buildWidgetTree(Widget superEditor) {
    if (_config.widgetTreeBuilder != null) {
      return _config.widgetTreeBuilder!(superEditor);
    }
    return MaterialApp(
      theme: _config.appTheme,
      // By default, Flutter chooses the shortcuts based on the platform. For "native" platforms,
      // the defaults already work correctly, because we set `debugDefaultTargetPlatformOverride` to force
      // the desired platform. However, for web Flutter checks for `kIsWeb`, which we can't control.
      //
      // Use our own version of the shortcuts, so we can set `debugIsWebOverride` to `true` to force
      // Flutter to pick the web shortcuts.
      shortcuts: defaultFlutterShortcuts,
      home: Scaffold(
        body: superEditor,
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Constrains the width and height of the given [superEditor], based on configurations
  /// in this class.
  Widget _buildConstrainedContent(Widget superEditor) {
    if (_config.editorSize != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _config.editorSize!.width,
          maxHeight: _config.editorSize!.height,
        ),
        child: superEditor,
      );
    }
    return superEditor;
  }

  /// Places [child] inside a [CustomScrollView], based on configurations in this class.
  Widget _buildAncestorScrollable({required Widget child}) {
    if (!_config.insideCustomScrollView) {
      return child;
    }

    return CustomScrollView(
      controller: _config.scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: child,
        ),
      ],
    );
  }

  /// Builds a [SuperEditor] widget based on the configuration of the given
  /// [testDocumentContext], as well as other configurations in this class.
  Widget _buildSuperEditor(TestDocumentContext testDocumentContext) {
    return _TestSuperEditor(
      testDocumentContext: testDocumentContext,
      testConfiguration: _config,
    );
  }
}

class _TestSuperEditor extends StatefulWidget {
  const _TestSuperEditor({
    required this.testDocumentContext,
    required this.testConfiguration,
  });

  final TestDocumentContext testDocumentContext;
  final SuperEditorTestConfiguration testConfiguration;

  @override
  State<_TestSuperEditor> createState() => _TestSuperEditorState();
}

class _TestSuperEditorState extends State<_TestSuperEditor> {
  late final SuperEditorIosControlsController? _iOsControlsController;
  late final SuperEditorAndroidControlsController? _androidControlsController;

  @override
  void initState() {
    super.initState();

    _iOsControlsController = SuperEditorIosControlsController(
      toolbarBuilder: widget.testConfiguration.iOSToolbarBuilder,
    );
    _androidControlsController = SuperEditorAndroidControlsController(
      toolbarBuilder: widget.testConfiguration.androidToolbarBuilder,
    );
  }

  @override
  void dispose() {
    _iOsControlsController?.dispose();
    _androidControlsController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget testSuperEditor = _buildSuperEditor();

    if (_iOsControlsController != null) {
      testSuperEditor = SuperEditorIosControlsScope(
        controller: _iOsControlsController!,
        child: testSuperEditor,
      );
    }

    if (_androidControlsController != null) {
      testSuperEditor = SuperEditorAndroidControlsScope(
        controller: _androidControlsController!,
        child: testSuperEditor,
      );
    }

    return testSuperEditor;
  }

  Widget _buildSuperEditor() {
    return SuperEditor(
      key: widget.testConfiguration.key,
      focusNode: widget.testDocumentContext.focusNode,
      autofocus: widget.testConfiguration.autoFocus,
      tapRegionGroupId: widget.testConfiguration.tapRegionGroupId,
      editor: widget.testDocumentContext.editor,
      document: widget.testDocumentContext.document,
      composer: widget.testDocumentContext.composer,
      documentLayoutKey: widget.testDocumentContext.layoutKey,
      inputSource: widget.testConfiguration.inputSource,
      selectionPolicies: widget.testConfiguration.selectionPolicies ?? const SuperEditorSelectionPolicies(),
      selectionStyle: widget.testConfiguration.selectionStyles,
      softwareKeyboardController: widget.testConfiguration.softwareKeyboardController,
      imePolicies: widget.testConfiguration.imePolicies ?? const SuperEditorImePolicies(),
      imeConfiguration: widget.testConfiguration.imeConfiguration,
      imeOverrides: widget.testConfiguration.imeOverrides,
      keyboardActions: [
        ...widget.testConfiguration.prependedKeyboardActions,
        ...(widget.testConfiguration.inputSource == TextInputSource.ime
            ? defaultImeKeyboardActions
            : defaultKeyboardActions),
        ...widget.testConfiguration.appendedKeyboardActions,
      ],
      selectorHandlers: widget.testConfiguration.selectorHandlers,
      gestureMode: widget.testConfiguration.gestureMode,
      stylesheet: widget.testConfiguration.stylesheet,
      componentBuilders: [
        ...widget.testConfiguration.addedComponents,
        ...(widget.testConfiguration.componentBuilders ?? defaultComponentBuilders),
      ],
      scrollController: widget.testConfiguration.scrollController,
      documentOverlayBuilders: _createOverlayBuilders(),
      plugins: widget.testConfiguration.plugins,
    );
  }

  List<SuperEditorLayerBuilder> _createOverlayBuilders() {
    // We show the default overlays except in the cases where we want to hide the caret
    // or use a custom `CaretStyle`. In those case, we don't include the defaults - we provide
    // a configured caret overlay builder, instead.
    //
    // If you introduce further configuration to overlay builders, make sure that in the default
    // situation, we're using `defaultSuperEditorDocumentOverlayBuilders`, so that most tests
    // verify the defaults that most apps will use.
    if (widget.testConfiguration.displayCaretWithExpandedSelection && widget.testConfiguration.caretStyle == null) {
      return defaultSuperEditorDocumentOverlayBuilders;
    }

    // Copy and modify the default overlay builders
    return [
      // Adds a Leader around the document selection at a focal point for the
      // iOS floating toolbar.
      const SuperEditorIosToolbarFocalPointDocumentLayerBuilder(),
      // Displays caret and drag handles, specifically for iOS.
      const SuperEditorIosHandlesDocumentLayerBuilder(),

      // Adds a Leader around the document selection at a focal point for the
      // Android floating toolbar.
      const SuperEditorAndroidToolbarFocalPointDocumentLayerBuilder(),
      // Displays caret and drag handles, specifically for Android.
      const SuperEditorAndroidHandlesDocumentLayerBuilder(),

      // Displays caret for typical desktop use-cases.
      DefaultCaretOverlayBuilder(
        displayCaretWithExpandedSelection: widget.testConfiguration.displayCaretWithExpandedSelection,
        caretStyle: widget.testConfiguration.caretStyle ?? const CaretStyle(),
      ),
    ];
  }
}

class SuperEditorTestConfiguration {
  SuperEditorTestConfiguration(this.document);

  ThemeData? appTheme;
  Key? key;
  FocusNode? focusNode;
  bool autoFocus = false;
  String? tapRegionGroupId;
  ui.Size? editorSize;
  final MutableDocument document;
  final addedRequestHandlers = <EditRequestHandler>[];
  final addedReactions = <EditReaction>[];
  GlobalKey? layoutKey;
  List<ComponentBuilder>? componentBuilders;
  Stylesheet? stylesheet;
  ScrollController? scrollController;
  bool insideCustomScrollView = false;
  DocumentGestureMode? gestureMode;
  TextInputSource? inputSource;
  SuperEditorSelectionPolicies? selectionPolicies;
  SelectionStyles? selectionStyles;
  bool displayCaretWithExpandedSelection = true;
  CaretStyle? caretStyle;
  SoftwareKeyboardController? softwareKeyboardController;
  SuperEditorImePolicies? imePolicies;
  SuperEditorImeConfiguration? imeConfiguration;
  DeltaTextInputClientDecorator? imeOverrides;
  Map<String, SuperEditorSelectorHandler>? selectorHandlers;
  final prependedKeyboardActions = <DocumentKeyboardAction>[];
  final appendedKeyboardActions = <DocumentKeyboardAction>[];
  final addedComponents = <ComponentBuilder>[];
  DocumentFloatingToolbarBuilder? androidToolbarBuilder;
  DocumentFloatingToolbarBuilder? iOSToolbarBuilder;

  DocumentSelection? selection;

  final plugins = <SuperEditorPlugin>{};

  WidgetTreeBuilder? widgetTreeBuilder;
}

/// Must return a widget tree containing the given [superEditor]
typedef WidgetTreeBuilder = Widget Function(Widget superEditor);

class TestDocumentContext {
  const TestDocumentContext._({
    required this.focusNode,
    required this.layoutKey,
    required this.document,
    required this.composer,
    required this.editor,
    required this.configuration,
  });

  final FocusNode focusNode;
  final GlobalKey layoutKey;
  // TODO: remove these document, editor, composer references
  final MutableDocument document;
  final MutableDocumentComposer composer;
  final Editor editor;
  SuperEditorContext findEditContext() =>
      ((find.byType(SuperEditor).evaluate().first as StatefulElement).state as SuperEditorState).editContext;

  final SuperEditorTestConfiguration configuration;
}

class ConfiguredSuperEditorWidget {
  const ConfiguredSuperEditorWidget(this.context, this.widget);

  final TestDocumentContext context;
  final Widget widget;
}

Matcher equalsMarkdown(String markdown) => DocumentEqualsMarkdownMatcher(markdown);

class DocumentEqualsMarkdownMatcher extends Matcher {
  const DocumentEqualsMarkdownMatcher(this._expectedMarkdown);

  final String _expectedMarkdown;

  @override
  Description describe(Description description) {
    return description.add("given Document has equivalent content to the given markdown");
  }

  @override
  bool matches(covariant Object target, Map<dynamic, dynamic> matchState) {
    return _calculateMismatchReason(target, matchState) == null;
  }

  @override
  Description describeMismatch(
    covariant Object target,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final mismatchReason = _calculateMismatchReason(target, matchState);
    if (mismatchReason != null) {
      mismatchDescription.add(mismatchReason);
    }
    return mismatchDescription;
  }

  String? _calculateMismatchReason(
    Object target,
    Map<dynamic, dynamic> matchState,
  ) {
    late Document actualDocument;
    if (target is Document) {
      actualDocument = target;
    } else {
      // If we weren't given a Document, then we expect to receive a Finder
      // that locates a SuperEditor, which contains a Document.
      if (target is! Finder) {
        return "the given target isn't a Document or a Finder: $target";
      }

      final document = SuperEditorInspector.findDocument(target);
      if (document == null) {
        return "Finder didn't match any SuperEditor widgets: $Finder";
      }
      actualDocument = document;
    }

    final actualMarkdown = serializeDocumentToMarkdown(actualDocument);
    final stringMatcher = equals(_expectedMarkdown);
    final matcherState = {};
    final matches = stringMatcher.matches(actualMarkdown, matcherState);
    if (matches) {
      // The document matches the markdown. Our matcher matches.
      return null;
    }

    return stringMatcher.describeMismatch(actualMarkdown, StringDescription(), matchState, false).toString();
  }
}

Matcher documentEquivalentTo(Document expectedDocument) => EquivalentDocumentMatcher(expectedDocument);

class EquivalentDocumentMatcher extends Matcher {
  const EquivalentDocumentMatcher(this._expectedDocument);

  final Document _expectedDocument;

  @override
  Description describe(Description description) {
    return description.add("given Document has equivalent content to expected Document");
  }

  @override
  bool matches(covariant Object target, Map<dynamic, dynamic> matchState) {
    return _calculateMismatchReason(target, matchState) == null;
  }

  @override
  Description describeMismatch(
    covariant Object target,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final mismatchReason = _calculateMismatchReason(target, matchState);
    if (mismatchReason != null) {
      mismatchDescription.add(mismatchReason);
    }
    return mismatchDescription;
  }

  String? _calculateMismatchReason(
    Object target,
    Map<dynamic, dynamic> matchState,
  ) {
    late Document actualDocument;
    if (target is Document) {
      actualDocument = target;
    } else {
      // If we weren't given a Document, then we expect to receive a Finder
      // that locates a SuperEditor, which contains a Document.
      if (target is! Finder) {
        return "the given target isn't a Document or a Finder: $target";
      }

      final document = SuperEditorInspector.findDocument(target);
      if (document == null) {
        return "Finder didn't match any SuperEditor widgets: $Finder";
      }
      actualDocument = document;
    }

    final messages = <String>[];
    bool nodeCountMismatch = false;
    bool nodeTypeOrContentMismatch = false;

    if (_expectedDocument.nodes.length != actualDocument.nodes.length) {
      messages
          .add("expected ${_expectedDocument.nodes.length} document nodes but found ${actualDocument.nodes.length}");
      nodeCountMismatch = true;
    } else {
      messages.add("document have the same number of nodes");
    }

    final maxNodeCount = max(_expectedDocument.nodes.length, actualDocument.nodes.length);
    final nodeComparisons = List.generate(maxNodeCount, (index) => ["", "", " "]);
    for (int i = 0; i < maxNodeCount; i += 1) {
      if (i < _expectedDocument.nodes.length && i < actualDocument.nodes.length) {
        nodeComparisons[i][0] = _expectedDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][1] = actualDocument.nodes[i].runtimeType.toString();

        if (_expectedDocument.nodes[i].runtimeType != actualDocument.nodes[i].runtimeType) {
          nodeComparisons[i][2] = "Wrong Type";
          nodeTypeOrContentMismatch = true;
        } else if (!_expectedDocument.nodes[i].hasEquivalentContent(actualDocument.nodes[i])) {
          nodeComparisons[i][2] = "Different Content";
          nodeTypeOrContentMismatch = true;
        }
      } else if (i < _expectedDocument.nodes.length) {
        nodeComparisons[i][0] = _expectedDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][1] = "NA";
        nodeComparisons[i][2] = "Missing Node";
      } else if (i < actualDocument.nodes.length) {
        nodeComparisons[i][0] = "NA";
        nodeComparisons[i][1] = actualDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][2] = "Missing Node";
      }
    }

    if (nodeCountMismatch || nodeTypeOrContentMismatch) {
      String messagesList = messages.join(", ");
      messagesList += "\n";
      messagesList += const TableRenderer().render(nodeComparisons, columns: ["Expected", "Actual", "Difference"]);
      return messagesList;
    }

    return null;
  }
}

/// A [ComponentBuilder] which builds an [ImageComponent] that always renders
/// images as a [SizedBox] with the given [size].
class FakeImageComponentBuilder implements ComponentBuilder {
  const FakeImageComponentBuilder({
    required this.size,
    this.fillColor,
  });

  /// The size of the image component.
  final ui.Size size;

  /// The color that fills the entire image component.
  final Color? fillColor;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    return null;
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! ImageComponentViewModel) {
      return null;
    }

    return ImageComponent(
      componentKey: componentContext.componentKey,
      imageUrl: componentViewModel.imageUrl,
      selection: componentViewModel.selection,
      selectionColor: componentViewModel.selectionColor,
      imageBuilder: (context, imageUrl) => ColoredBox(
        color: fillColor ?? Colors.transparent,
        child: SizedBox(
          height: size.height,
          width: size.width,
        ),
      ),
    );
  }
}

/// Builds [TaskComponentViewModel]s and [ExpandingTaskComponent]s for every
/// [TaskNode] in a document.
class ExpandingTaskComponentBuilder extends ComponentBuilder {
  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! TaskNode) {
      return null;
    }

    return TaskComponentViewModel(
      nodeId: node.id,
      padding: EdgeInsets.zero,
      isComplete: node.isComplete,
      setComplete: (bool isComplete) {},
      text: node.text,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
    );
  }

  @override
  Widget? createComponent(
      SingleColumnDocumentComponentContext componentContext, SingleColumnLayoutComponentViewModel componentViewModel) {
    if (componentViewModel is! TaskComponentViewModel) {
      return null;
    }

    return ExpandingTaskComponent(
      key: componentContext.componentKey,
      viewModel: componentViewModel,
    );
  }
}

/// A task component which expands its height when it's selected.
class ExpandingTaskComponent extends StatefulWidget {
  const ExpandingTaskComponent({
    super.key,
    required this.viewModel,
  });

  final TaskComponentViewModel viewModel;

  @override
  State<ExpandingTaskComponent> createState() => _ExpandingTaskComponentState();
}

class _ExpandingTaskComponentState extends State<ExpandingTaskComponent>
    with ProxyDocumentComponent<ExpandingTaskComponent>, ProxyTextComposable {
  final _textKey = GlobalKey();

  @override
  GlobalKey<State<StatefulWidget>> get childDocumentComponentKey => _textKey;

  @override
  TextComposable get childTextComposable => childDocumentComponentKey.currentState as TextComposable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          key: _textKey,
          text: widget.viewModel.text,
          textStyleBuilder: widget.viewModel.textStyleBuilder,
          textSelection: widget.viewModel.selection,
          selectionColor: widget.viewModel.selectionColor,
          highlightWhenEmpty: widget.viewModel.highlightWhenEmpty,
        ),
        if (widget.viewModel.selection != null) //
          const SizedBox(height: 20)
      ],
    );
  }
}

class StandardEditorPieces {
  StandardEditorPieces(this.document, this.composer, this.editor);

  final Document document;
  final DocumentComposer composer;
  final Editor editor;
}

/// Fake [DocumentLayout], intended for tests that interact with
/// a logical [DocumentLayout] but do not depend upon a real
/// widget tree with a real [DocumentLayout] implementation.
class FakeDocumentLayout with Mock implements DocumentLayout {}

/// Fake [SuperEditorScroll], intended for tests that interact
/// with logical resources but do not depend upon a real widget
/// tree with a real `Scrollable`.
class FakeSuperEditorScroller implements DocumentScroller {
  @override
  void dispose() {}

  @override
  double get viewportDimension => throw UnimplementedError();

  @override
  double get minScrollExtent => throw UnimplementedError();

  @override
  double get maxScrollExtent => throw UnimplementedError();

  @override
  double get scrollOffset => throw UnimplementedError();

  @override
  void jumpTo(double newScrollOffset) => throw UnimplementedError();

  @override
  void jumpBy(double delta) => throw UnimplementedError();

  @override
  void animateTo(double to, {required Duration duration, Curve curve = Curves.easeInOut}) => throw UnimplementedError();

  @override
  void attach(ScrollPosition scrollPosition) => throw UnimplementedError();

  @override
  void detach() => throw UnimplementedError();

  @override
  void addScrollChangeListener(ui.VoidCallback listener) => throw UnimplementedError();

  @override
  void removeScrollChangeListener(ui.VoidCallback listener) => throw UnimplementedError();
}
