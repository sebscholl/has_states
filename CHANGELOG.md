## Released

## [0.0.3] - 2024-01-14

- Adding `current_state(state_name)` method
- Adding DB indexes for state lookups
- Adding query methods for state types on stateable (`stateable.state_type` and `stateable.state_types`)

## [0.0.2] - 2024-12-23

- Added test coverage
- Refactor of State model into a inheritable Base class
- Single Table Inheritance (STI) support for custom state types
- Ability to create custom state classes by inheriting from `HasStates::Base`
- Default state class `HasStates::State` for basic state management
- Example implementation of custom state types in documentation

## [0.0.1] - 2024-12-21

- Initial release
- See READme.md
