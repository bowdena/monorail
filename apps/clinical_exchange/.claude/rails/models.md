# Rails Model Guidelines
# Models - DHH Rails Style

## Concerns for Horizontal Behavior

Models heavily use concerns. A typical Card model includes 14+ concerns:

```ruby
class Card < ApplicationRecord
  include Assignable
  include Attachments
  include Broadcastable
  include Closeable
  include Colored
  include Eventable
  include Golden
  include Mentions
  include Multistep
  include Pinnable
  include Postponable
  include Readable
  include Searchable
  include Taggable
  include Watchable
end
```

Each concern is self-contained with associations, scopes, and methods.

**Naming:** Adjectives describing capability (`Closeable`, `Publishable`, `Watchable`)

## State as Records, Not Booleans

Instead of boolean columns, create separate records:

```ruby
# Instead of:
closed: boolean
is_golden: boolean
postponed: boolean

# Create records:
class Card::Closure < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end

class Card::Goldness < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end

class Card::NotNow < ApplicationRecord
  belongs_to :card
  belongs_to :creator, class_name: "User"
end
```

**Benefits:**
- Automatic timestamps (when it happened)
- Track who made changes
- Easy filtering via joins and `where.missing`
- Enables rich UI showing when/who

**In the model:**
```ruby
module Closeable
  extend ActiveSupport::Concern

  included do
    has_one :closure, dependent: :destroy
  end

  def closed?
    closure.present?
  end

  def close(creator: Current.user)
    create_closure!(creator: creator)
  end

  def reopen
    closure&.destroy
  end
end
```

**Querying:**
```ruby
Card.joins(:closure)         # closed cards
Card.where.missing(:closure) # open cards
```

## Callbacks - Used Sparingly

Only 38 callback occurrences across 30 files in Fizzy. Guidelines:

**Use for:**
- `after_commit` for async work
- `before_save` for derived data
- `after_create_commit` for side effects

**Avoid:**
- Complex callback chains
- Business logic in callbacks
- Synchronous external calls

```ruby
class Card < ApplicationRecord
  after_create_commit :notify_watchers_later
  before_save :update_search_index, if: :title_changed?

  private
    def notify_watchers_later
      NotifyWatchersJob.perform_later(self)
    end
end
```

## Scope Naming

Standard scope names:

```ruby
class Card < ApplicationRecord
  scope :chronologically, -> { order(created_at: :asc) }
  scope :reverse_chronologically, -> { order(created_at: :desc) }
  scope :alphabetically, -> { order(title: :asc) }
  scope :latest, -> { reverse_chronologically.limit(10) }

  # Standard eager loading
  scope :preloaded, -> { includes(:creator, :assignees, :tags) }

  # Parameterized
  scope :indexed_by, ->(column) { order(column => :asc) }
  scope :sorted_by, ->(column, direction = :asc) { order(column => direction) }
end
```

## Plain Old Ruby Objects

POROs namespaced under parent models:

```ruby
# app/models/event/description.rb
class Event::Description
  def initialize(event)
    @event = event
  end

  def to_s
    # Presentation logic for event description
  end
end

# app/models/card/eventable/system_commenter.rb
class Card::Eventable::SystemCommenter
  def initialize(card)
    @card = card
  end

  def comment(message)
    # Business logic
  end
end

# app/models/user/filtering.rb
class User::Filtering
  # View context bundling
end
```

**NOT used for service objects.** Business logic stays in models.

## Class Methods

Declare them in a `class << self` block. Never `def self.method`.

```ruby
# ✅ Good
class Patient < ApplicationRecord
  class << self
    def remember(found)
      find_or_initialize_by(urn: found.urn)
    end
  end
end

# ❌ Bad
class Patient < ApplicationRecord
  def self.remember(found)
    find_or_initialize_by(urn: found.urn)
  end
end
```

One block per class, holding every class method, so the class-level API
reads as a unit. Private class methods go behind `private` inside that
block — `private_class_method` is not needed there.

## Method Naming

**Verbs** - Actions that change state:
```ruby
card.close
card.reopen
card.gild      # make golden
card.ungild
board.publish
board.archive
```

**Predicates** - Queries derived from state:
```ruby
card.closed?    # closure.present?
card.golden?    # goldness.present?
board.published?
```

**Avoid** generic setters:
```ruby
# Bad
card.set_closed(true)
card.update_golden_status(false)

# Good
card.close
card.ungild
```

## Primary Keys — UUIDv7, and you must say so

Every table is keyed by a version 7 UUID. Records reach the browser as
URLs, and a sequential id there is an invitation to walk the table.
Version 7 is time-ordered, so rows still insert at the end of the index
rather than scattering the way version 4 does.

Postgres 18 generates them natively — `uuidv7()`, no extension.

**Rails will not do this for you.** `create_table id: :uuid` hard-codes
`gen_random_uuid()`, which is version 4, and Rails 8.1 knows nothing
about `uuidv7`. The generator config gives you the uuid *type*; naming
the function is on the migration:

```ruby
# ✅ Good
create_table :appointments, id: :uuid, default: -> { "uuidv7()" } do |t|
  t.references :patient, type: :uuid, foreign_key: true
  t.timestamps
end

# ❌ Bad — silently version 4, random, and nothing will tell you
create_table :appointments, id: :uuid do |t|
```

Miss the `default:` and the table works fine; the ids are simply random
and scatter across the index. Nothing fails, so check it in review:
after migrating, `db/schema.rb` must read
`id: :uuid, default: -> { "uuidv7()" }` for the new table.

Foreign keys to a uuid-keyed table need `type: :uuid` on the reference,
or the migration fails with a type mismatch.

There was an initializer that patched the adapter to make this
automatic. It was dropped deliberately: it overrode a Rails internal
that could move under us. Explicit migrations, checked in review, are
the trade.

## Validation Philosophy

Minimal validations on models. Use contextual validations on form/operation objects:

```ruby
# Model - minimal
class User < ApplicationRecord
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

# Form object - contextual
class Signup
  include ActiveModel::Model

  attr_accessor :email, :name, :terms_accepted

  validates :email, :name, presence: true
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?
    User.create!(email: email, name: name)
  end
end
```

**Prefer database constraints** over model validations for data integrity:
```ruby
# migration
add_index :users, :email, unique: true
add_foreign_key :cards, :boards
```

## Let It Crash Philosophy

Use bang methods that raise exceptions on failure:

```ruby
# Preferred - raises on failure
@card = Card.create!(card_params)
@card.update!(title: new_title)
@comment.destroy!

# Avoid - silent failures
@card = Card.create(card_params)  # returns false on failure
if @card.save
  # ...
end
```

Let errors propagate naturally. Rails handles ActiveRecord::RecordInvalid with 422 responses.

## Default Values with Lambdas

Use lambda defaults for associations with Current:

```ruby
class Card < ApplicationRecord
  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { Current.account }
end

class Comment < ApplicationRecord
  belongs_to :commenter, class_name: "User", default: -> { Current.user }
end
```

Lambdas ensure dynamic resolution at creation time.

## Rails 7.1+ Model Patterns

**Normalizes** - clean data before validation:
```ruby
class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :phone, with: ->(phone) { phone.gsub(/\D/, "") }
end
```

**Delegated Types** - replace polymorphic associations:
```ruby
class Message < ApplicationRecord
  delegated_type :messageable, types: %w[Comment Reply Announcement]
end

# Now you get:
message.comment?        # true if Comment
message.comment         # returns the Comment
Message.comments        # scope for Comment messages
```

**Store Accessor** - structured JSON storage:
```ruby
class User < ApplicationRecord
  store :settings, accessors: [:theme, :notifications_enabled], coder: JSON
end

user.theme = "dark"
user.notifications_enabled = true
```

## Concern Guidelines

- **50-150 lines** per concern (most are ~100)
- **Cohesive** - related functionality only
- **Named for capabilities** - `Closeable`, `Watchable`, not `CardHelpers`
- **Self-contained** - associations, scopes, methods together
- **Not for mere organization** - create when genuine reuse needed

**Touch chains** for cache invalidation:
```ruby
class Comment < ApplicationRecord
  belongs_to :card, touch: true
end

class Card < ApplicationRecord
  belongs_to :board, touch: true
end
```

When comment updates, card's `updated_at` changes, which cascades to board.

**Transaction wrapping** for related updates:
```ruby
class Card < ApplicationRecord
  def close(creator: Current.user)
    transaction do
      create_closure!(creator: creator)
      record_event(:closed)
      notify_watchers_later
    end
  end
end
```
