

class RateLimiterService {
  final Map<String, List<DateTime>> _requestHistory = {};
  final int _maxRequests;
  final Duration _window;

  RateLimiterService({int maxRequests = 10, Duration window = const Duration(hours: 1)})
      : _maxRequests = maxRequests,
        _window = window;

  bool isAllowed(String identifier) {
    final now = DateTime.now();
    final windowStart = now.subtract(_window);

    // Get or create request history for this identifier
    if (!_requestHistory.containsKey(identifier)) {
      _requestHistory[identifier] = [];
    }

    final history = _requestHistory[identifier]!;

    // Remove old requests outside the window
    history.removeWhere((timestamp) => timestamp.isBefore(windowStart));

    // Check if we're under the limit
    if (history.length >= _maxRequests) {
      return false;
    }

    // Add current request
    history.add(now);
    return true;
  }

  int getRemainingRequests(String identifier) {
    final now = DateTime.now();
    final windowStart = now.subtract(_window);

    if (!_requestHistory.containsKey(identifier)) {
      return _maxRequests;
    }

    final history = _requestHistory[identifier]!;
    history.removeWhere((timestamp) => timestamp.isBefore(windowStart));

    return _maxRequests - history.length;
  }

  void clearHistory(String identifier) {
    _requestHistory.remove(identifier);
  }

  void clearAllHistory() {
    _requestHistory.clear();
  }
} 