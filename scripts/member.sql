CREATE TABLE IF NOT EXISTS member
(
    id            INT                                    NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       TEXT UNIQUE,
    name          TEXT                                   NOT NULL UNIQUE,
    pass          TEXT                                   NOT NULL,
    nick_name     TEXT,
    remote_access BOOLEAN      DEFAULT false,
    is_root       BOOLEAN      DEFAULT false,
    perms         TEXT[],
    settings      JSON         DEFAULT '{}'::JSON,
    created_at    TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at    TIMESTAMP(3) DEFAULT CURRENT_TIMESTAMP NOT NULL
);