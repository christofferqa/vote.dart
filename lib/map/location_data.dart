class LocationData {
  static final int maxCandidateCount = 26;
  static final int _ACharCode = 65;
  static final num _span = 20;
  final ReadOnlyCollection<MapPlayer> candidates;
  final ReadOnlyCollection<MapPlayer> voters;

  static HashMap<int, num> _candidateHues;

  LocationData(this.voters, this.candidates) {
    assert(this.candidates.length > 0);
  }

  factory LocationData.random() {
    final spanTweak = _span / (_span - 1);

    // 100 voters from 1,1 to 10,10
    final voters = new List<MapPlayer>();
    for(var i = 0; i < _span; i++) {
      for(var j = 0; j < _span; j++) {
        voters.add(new MapPlayer(new Coordinate(i * spanTweak, j * spanTweak)));
      }
    }

    // silly spinning wheels to get a semi-random value out of Math.random
    final blah = Clock.now() % 1000;
    for(int i = 0; i < blah; i++) {
      Math.random();
    }

    final coords = new List<Vector>();
    final middle = new Vector(0.5, 0.5);
    coords.add(middle);

    final bool mirror = false;

    for(var i = 0; i < 4; i++) {
      var coord = new Vector(Math.random(), Math.random());
      coords.add(coord);
      if(mirror) {
        final delta = middle - coord;
        coords.add(middle + delta);
        i++;
      }
    }

    final candidates = new List<MapPlayer>();
    $(coords)
      .select((c) => c.scale(_span))
      .forEachWithIndex((c,i) {
        final candidate = new MapPlayer(c, getCandidateName(i));
        candidates.add(candidate);
      });

    return new LocationData(
      new ReadOnlyCollection<MapPlayer>.wrap(voters),
      new ReadOnlyCollection<MapPlayer>.wrap(candidates));

  }

  LocationData cloneAndRemove(MapPlayer mp) {
    requireArgumentNotNull(mp, 'mp');

    var newCans = candidates.where((e) => e != mp).toReadOnlyCollection();

    return new LocationData(voters, newCans);
  }

  LocationData cloneAndAddCandidate() {
    assert(candidates.length < 26);
    var newCans = candidates.toList();

    int i;
    for(i = 0; i < newCans.length; i++) {
      final mp = newCans[i];
      assert(mp.name.length == 1);
      final mpCC = mp.name.charCodeAt(0);
      final letterIndex = mpCC - _ACharCode;
      assert(letterIndex >= i);

      if(letterIndex > i) {
        break;
      }
    }

    final newName = getCandidateName(i);

    var coord = new Vector(Math.random(), Math.random());
    final loc = coord.scale(_span);
    final mp = new MapPlayer(loc, newName);

    newCans.insertRange(i, 1, mp);

    return new LocationData(voters, new ReadOnlyCollection(newCans));
  }

  static num getHue(MapPlayer candidate) {
    if(_candidateHues == null) {
      final halfLetterCount = maxCandidateCount ~/ 2;
      _candidateHues = new HashMap<int, num>();
      for(int i = 0; i < maxCandidateCount; i++) {
        int j = i;
        if(i % 2 == 1) {
          j = (i + halfLetterCount) % maxCandidateCount;
        }
        final spot = 360 * j / maxCandidateCount;
        _candidateHues[i] = spot;
      }
    }
    final letter = candidate.name;
    assert(letter != null && letter.length == 1);
    final letterCode = (letter.charCodeAt(0) - _ACharCode);
    assert(letterCode >= 0 && letterCode < 26);

    return _candidateHues[letterCode];
  }

  static String getCandidateName(int i) {
    requireArgument(i >= 0);
    requireArgument(i < maxCandidateCount);
    return new String.fromCharCodes([i + _ACharCode]);
  }
}
