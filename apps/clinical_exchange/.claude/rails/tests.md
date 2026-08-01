# Rails Test Guidelines (RSpec)

## Core Principles

- TDD per commit: write a failing spec first, write the implementation,
  confirm the spec passes, then commit spec + implementation together as a
  single thin slice
- Test behaviour, not implementation — renaming a private method should not break a spec
- Test valid, edge, and invalid cases
- Group expectations within a single `it` block when testing the same action —
  one `it` per expectation is slower and adds noise without adding clarity
- Use travel_to for deterministic time-dependent assertions
- Tests ship with features
- Fixes always ship with a regression test that would have caught the issue —
  write the failing spec before the implementation, never after
- Run `bin/rails lint` only after the specs pass — not before, not simultaneously
- Integration tests validate complete workflows

## Test Types

### Model specs (`spec/models/`)
Validations, associations, scopes, instance methods, class methods, enums, database constraints.

### Request specs (`spec/requests/`)
Use request specs, not controller specs. Request specs exercise the router, middleware, and rack stack.

Use for: authorization checks, routing, response status codes, flash messages, redirects.

### System specs (`spec/system/`)
End-to-end user workflows, multi-step interactions, JavaScript behaviour, form submissions.

Naming: `user_action_spec.rb` or `feature_description_spec.rb`

### Service/integration specs (`spec/services/`, `spec/integration/`)
Complex business logic, multi-step workflows, external API integrations, background jobs.

## Structure

### Describe / context / it

- `describe` per class; `.method` for class methods, `#method` for instance methods
- `context` starts with "when", "with", or "without"
- `it` descriptions: third-person present tense, under 40 characters, never use "should"
- If an `it` description needs more than 40 characters, split it into a `context` + shorter `it`

```ruby
# ✅ Good
describe '#published?' do
  context 'when status is published' do
    it 'returns true' do
```

```ruby
# ❌ Bad
it 'should return true when the article status is set to published' do
```

### Arrange-Act-Assert

Organise each example with clear phases separated by blank lines:

```ruby
it 'creates a new article' do
  user = create(:user)
  attributes = { title: 'Test Article', body: 'Content' }

  article = Article.create(attributes)

  expect(article).to be_persisted
  expect(article.title).to eq('Test Article')
end
```

### Write self-contained tests

Do not use `let`, `let!`, `before`, or shared examples. Set up everything inside the `it` block.
Tests should be readable top-to-bottom without jumping to shared setup.

```ruby
# ✅ Good
context 'when last name is not present' do
  it 'returns the first name' do
    user = build(:user, first_name: 'Edson', last_name: nil)

    expect(user.full_name).to eq('Edson')
  end
end

# ❌ Bad
describe '#full_name' do
  let(:user) { build(:user, first_name: 'Edson', last_name: 'Pelé') }

  context 'when last name is not present' do
    it 'returns the first name' do
      user.last_name = nil
      expect(user.full_name).to eq('Edson')
    end
  end
end
```

### `described_class`

Use `described_class` instead of naming the class directly so renames don't require updating specs.

```ruby
# ✅ Good
describe Pilot do
  describe '.most_successful' do
    it 'returns the top pilot' do
      result = described_class.most_successful
      expect(result).to eq(expected_pilot)
    end
  end
end

# ❌ Bad
describe Pilot do
  describe '.most_successful' do
    it 'returns the top pilot' do
      result = Pilot.most_successful
```

Avoid `subject` except as `subject { described_class.new }` with no constructor arguments.

## Factories

- Use FactoryBot; define the minimal valid factory, use traits for variations
- Prefer `build` over `create` when persistence is not required — faster, no database hit
- Always specify the conditions under test explicitly — do not rely on factory defaults

```ruby
# ✅ Good — conditions explicit
it 'returns the full name' do
  user = create(:user, first_name: 'Santos', last_name: 'Dumont')

  expect(user.full_name).to eq('Santos Dumont')
end

# ❌ Bad — relies on factory defaults
it 'returns the full name' do
  user = create(:user)

  expect(user.full_name).to eq('Santos Dumont')
end
```

Factory organisation: associations first, then attributes alphabetically, then traits alphabetically.

```ruby
FactoryBot.define do
  factory :article do
    user
    category

    body { 'Article content' }
    status { :draft }
    title { 'Sample Article' }

    trait :published do
      status { :published }
      published_at { 1.day.ago }
    end
  end
end
```

Create only the data needed for each test — excess records slow the suite and obscure intent.

## Mocking and Stubbing

- Stub at the boundary of the system under test, not inside it
- Use `instance_double` over `double` — it verifies the stubbed methods exist on the real class
- Never stub methods on the class being tested
- Never use `allow_any_instance_of` — use dependency injection instead
- Mock external dependencies (HTTP, third-party services) with WebMock or VCR

```ruby
# ✅ Good — instance_double catches method mismatches
payment_service = instance_double(PaymentService)
allow(payment_service).to receive(:charge).and_return(true)
order = Order.new(payment_service: payment_service)

# ❌ Bad — any_instance_of
allow_any_instance_of(PaymentService).to receive(:charge)

# ❌ Bad — double doesn't verify methods exist
payment_service = double(:payment_service, charge: true)
```

## What to Avoid

| Avoid | Why |
|-------|-----|
| `let` / `let!` | Creates hidden state; requires tracing variables across blocks |
| `before` hooks | Same reason; setup should live next to the assertion it supports |
| Shared examples | Adds indirection; tests should be explicit, not DRY |
| Private method specs | Test the public interface; private methods are covered indirectly |
| `should` syntax | Use `expect` syntax only |
| CSS class assertions in system specs | Couples tests to styling; use semantic selectors |

```ruby
# ✅ Good — semantic selectors
expect(page).to have_selector('[data-testid="user-modal"]')
expect(page).to have_button('Submit')

# ❌ Bad — CSS implementation detail
expect(page).to have_css('.bg-red-500')
```

## Removing or disabling tests

**Never remove a test unless explicitly asked.** If a test appears deprecated or
redundant, flag it to the user and ask for confirmation before deleting it.

**Never disable a RuboCop rule in a spec without confirmation.** Before adding
any `# rubocop:disable` comment, stop and present the user with:

1. Why the rule is firing.
2. At least one alternative approach that avoids the disable, with a code
   example.
3. An explanation of the trade-off so the user can make an informed choice.

Only add the disable after the user has reviewed the options and confirmed it
is the right call.

```ruby
# ❌ Bad — silently suppresses the rule
# rubocop:disable RSpec/AnyInstance
allow_any_instance_of(MyJob).to receive(:fetch_path).and_return("/tmp/f")
# rubocop:enable RSpec/AnyInstance

# ✅ Better — let the private method run naturally; assert shape, not value
allow(MyService).to receive(:new).and_return(service_double)
expect(MyService).to have_received(:new).with(
  record: record,
  path: instance_of(String)
)

# ✅ Also acceptable — inject the dependency so the instance is reachable
job = MyJob.new
allow(job).to receive(:fetch_path).and_return("/tmp/f")
job.perform(record.id)
```

## Shoulda Matchers

Use for concise association and validation assertions:

```ruby
describe 'associations' do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:comments) }
end

describe 'validations' do
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_length_of(:title).is_at_most(255) }
end
```

## Request Spec Authentication

Use direct session assignment, not stubs:

```ruby
# ✅ Good
session[:user_id] = user.id

# ❌ Bad
allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(true)
```

Request spec example:

```ruby
RSpec.describe 'Articles' do
  describe 'POST /articles' do
    context 'with valid parameters' do
      it 'creates article and redirects' do
        user = create(:user)
        session[:user_id] = user.id

        expect do
          post articles_path, params: { article: { title: 'Test', body: 'Content' } }
        end.to change(Article, :count).by(1)

        expect(response).to redirect_to(Article.last)
      end
    end

    context 'with invalid parameters' do
      it 'does not create article and returns unprocessable entity' do
        user = create(:user)
        session[:user_id] = user.id

        expect do
          post articles_path, params: { article: { title: '', body: '' } }
        end.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
```
