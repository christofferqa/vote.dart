import 'dart:html';
import 'package:bot/bot.dart';
import 'package:bot/html.dart';
import 'package:bot/retained.dart';
import 'package:vote.dart/calc.dart';
import 'package:vote.dart/html.dart';
import 'package:vote.dart/map.dart';
import 'package:vote.dart/retained.dart';
import 'package:vote.dart/vote.dart';

main(){
  CanvasElement canvas = query("#content");
  DivElement pluralityDiv = query('#pluralityView');
  DivElement distanceDiv = query('#distanceView');
  DivElement condorcetDiv = query('#condorcetView');
  DivElement canManDiv = query('#canManView');
  DivElement irvDiv = query('#irvView');
  var demo = new VoteDemo(canvas, pluralityDiv, distanceDiv, condorcetDiv,
      canManDiv, irvDiv);
  demo._requestFrame();
}

class VoteDemo{
  final CanvasElement _canvas;
  final Stage _stage;
  final Dragger _dragger;

  final CalcEngine _calcEngine = new CalcEngine();

  final RootMapElement _rootMapElement;
  final HashMap<MapPlayer, num> _playerHues = new HashMap<MapPlayer, num>();
  final CondorcetView _condorcetView;
  final IrvView _irvView;
  final DistanceView _distanceView;
  final PluralityView _pluralityView;
  final CandidateManagerView _canManView;

  HashMap<MapPlayer, num> _candidateHues;

  Coordinate _mouseLocation;
  MapPlayer _overCandidate, _dragCandidate;
  bool _frameRequested = false;

  factory VoteDemo(CanvasElement canvas, DivElement pluralityDiv,
    DivElement distanceDiv, DivElement condorcetDiv, DivElement canManDiv,
    DivElement irvDiv) {
    var voterMap = new RootMapElement(canvas.width, canvas.height);

    //
    // Create the stage, etc
    //

    final stage = new Stage(canvas, voterMap);

    var distanceView = new DistanceView(distanceDiv);

    var pluralityView = new PluralityView(pluralityDiv);

    var condorcetView = new CondorcetView(condorcetDiv);
    final irvView = new IrvView(irvDiv);

    final canManView = new CandidateManagerView(canManDiv);

    var dragger = new Dragger(canvas);

    return new VoteDemo._internal(canvas, stage, dragger, voterMap,
      condorcetView, pluralityView, distanceView, canManView, irvView);
  }

  VoteDemo._internal(this._canvas, this._stage, this._dragger,
      this._rootMapElement, this._condorcetView, this._pluralityView,
      this._distanceView, this._canManView, this._irvView) {
    _dragger.dragDelta.add(_onDrag);
    _dragger.dragStart.add(_onDragStart);

    _canvas.on.mouseMove.add(_canvas_mouseMove);
    _canvas.on.mouseOut.add(_canvas_mouseOut);

    _calcEngine.locationDataChanged.add(_locationDataUpdated);
    _calcEngine.distanceElectionChanged.add(_distanceElectionUpdated);
    _calcEngine.pluralityElectionChanged.add(_pluralityElectionUpdated);
    _calcEngine.condorcetElectionChanged.add(_condorcetElectionUpdated);
    _calcEngine.irvElectionChanged.add(_irvElectionUpdated);
    _calcEngine.voterHueMapperChanged.add(_voterHexMapperUpdated);

    _rootMapElement.candidatesMoved.add((data) {
      _calcEngine.candidatesMoved();
    });

    _stage.invalidated.add((args) {
      _requestFrame();
    });

    _canManView.candidateRemoveRequest.add((data) {
      _calcEngine.removeCandidate(data);
    });

    _canManView.newCandidateRequest.add((args) {
      _calcEngine.addCandidate();
    });

    _condorcetView.hoverChanged.add((args) {
      _updateHighlightCandidates(_condorcetView.highlightCandidates);
    });

    _irvView.hoverChanged.add((args) {
      _updateHighlightCandidates(_irvView.highlightCandidates);
    });

    final initialData = new LocationData.random();

    _calcEngine.locationData = initialData;
  }

  void _updateHighlightCandidates(List candidates) {
    _calcEngine.hoverPair = candidates;
    _rootMapElement.showOnlyPlayers = candidates;
  }

  void _locationDataUpdated(dynamic args) {
    assert(_calcEngine.locationData != null);
    final locData = _calcEngine.locationData;
    _rootMapElement.locationData = locData;
    _canManView.candidates = locData.candidates;
  }

  void _distanceElectionUpdated(dynamic args) {
    assert(_calcEngine.distanceElection != null);
    _distanceView.election = _calcEngine.distanceElection;
    _requestFrame();
  }

  void _pluralityElectionUpdated(dynamic args) {
    assert(_calcEngine.pluralityElection != null);
    _pluralityView.election = _calcEngine.pluralityElection;
    _requestFrame();
  }

  void _condorcetElectionUpdated(dynamic args) {
    assert(_calcEngine.condorcetElection != null);
    _condorcetView.election = _calcEngine.condorcetElection;
    _requestFrame();
  }

  void _irvElectionUpdated(args) {
    assert(_calcEngine.irvElection != null);
    _irvView.election = _calcEngine.irvElection;
    _requestFrame();
  }

  void _voterHexMapperUpdated(dynamic args) {
    assert(_calcEngine.voterHexMap != null);
    _rootMapElement.voterHexMap = _calcEngine.voterHexMap;
    _requestFrame();
  }

  void _requestFrame(){
    if(!_frameRequested) {
      _frameRequested = true;
      window.requestAnimationFrame(_onFrame);
    }
  }

  void _onDrag(Vector delta) {
    assert(_dragCandidate != null);
    _rootMapElement.dragCandidate(_dragCandidate, delta);
    _requestFrame();
  }

  void _onDragStart(CancelableEventArgs e) {
    if(_overCandidate == null) {
      e.cancel();
    } else {
      _dragCandidate = _overCandidate;
    }
  }

  void _onFrame(double highResTime){
    _stage.draw();

    _condorcetView.draw();
    _irvView.draw();
    _pluralityView.draw();
    _distanceView.draw();
    _canManView.draw();
    _frameRequested = false;
  }

  void _canvas_mouseMove(MouseEvent e){
    _setMouse(getMouseEventCoordinate(e));
  }

  void _canvas_mouseOut(MouseEvent e){
    _setMouse(null);
  }

  void _setMouse(Coordinate value) {
    _mouseLocation = value;
    final hits = Mouse.markMouseOver(_stage, _mouseLocation);
    if(hits != null && hits.length > 0 && hits[0] is CandidateElement) {
      _canvas.style.cursor = 'pointer';
      final CandidateElement ce = hits[0];
      _overCandidate = ce.player;
    } else {
      _overCandidate = null;
    }

    if(_overCandidate != null || _dragCandidate != null) {
      _canvas.style.cursor = 'pointer';
    } else {
      _canvas.style.cursor = 'auto';
    }
  }
}