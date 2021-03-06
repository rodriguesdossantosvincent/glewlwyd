DROP TABLE IF EXISTS gpo_client_registration;
DROP TABLE IF EXISTS gpo_subject_identifier;
DROP TABLE IF EXISTS gpo_id_token;
DROP TABLE IF EXISTS gpo_access_token_scope;
DROP TABLE IF EXISTS gpo_access_token;
DROP TABLE IF EXISTS gpo_refresh_token_scope;
DROP TABLE IF EXISTS gpo_refresh_token;
DROP TABLE IF EXISTS gpo_code_scheme;
DROP TABLE IF EXISTS gpo_code_scope;
DROP TABLE IF EXISTS gpo_code;
DROP TABLE IF EXISTS gpo_client_token_request;
DROP TABLE IF EXISTS gpo_device_scheme;
DROP TABLE IF EXISTS gpo_device_authorization_scope;
DROP TABLE IF EXISTS gpo_device_authorization;

CREATE TABLE gpo_code (
  gpoc_id SERIAL PRIMARY KEY,
  gpoc_plugin_name VARCHAR(256) NOT NULL,
  gpoc_authorization_type SMALLINT NOT NULL,
  gpoc_username VARCHAR(256) NOT NULL,
  gpoc_client_id VARCHAR(256) NOT NULL,
  gpoc_redirect_uri VARCHAR(512) NOT NULL,
  gpoc_code_hash VARCHAR(512) NOT NULL,
  gpoc_nonce VARCHAR(512),
  gpoc_claims_request TEXT DEFAULT NULL,
  gpoc_expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gpoc_issued_for VARCHAR(256), -- IP address or hostname
  gpoc_user_agent VARCHAR(256),
  gpoc_code_challenge VARCHAR(128),
  gpoc_enabled SMALLINT DEFAULT 1
);
CREATE INDEX i_gpoc_code_hash ON gpo_code(gpoc_code_hash);
CREATE INDEX i_gpoc_code_challenge ON gpo_code(gpoc_code_challenge);

CREATE TABLE gpo_code_scope (
  gpocs_id SERIAL PRIMARY KEY,
  gpoc_id INTEGER,
  gpocs_scope VARCHAR(128) NOT NULL,
  FOREIGN KEY(gpoc_id) REFERENCES gpo_code(gpoc_id) ON DELETE CASCADE
);

CREATE TABLE gpo_code_scheme (
  gpoch_id SERIAL PRIMARY KEY,
  gpoc_id INTEGER,
  gpoch_scheme_module VARCHAR(128) NOT NULL,
  FOREIGN KEY(gpoc_id) REFERENCES gpo_code(gpoc_id) ON DELETE CASCADE
);

CREATE TABLE gpo_refresh_token (
  gpor_id SERIAL PRIMARY KEY,
  gpor_plugin_name VARCHAR(256) NOT NULL,
  gpor_authorization_type SMALLINT NOT NULL,
  gpoc_id INTEGER DEFAULT NULL,
  gpor_username VARCHAR(256) NOT NULL,
  gpor_client_id VARCHAR(256),
  gpor_claims_request TEXT DEFAULT NULL,
  gpor_issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gpor_expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gpor_last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  gpor_duration INTEGER,
  gpor_rolling_expiration SMALLINT DEFAULT 0,
  gpor_issued_for VARCHAR(256), -- IP address or hostname
  gpor_user_agent VARCHAR(256),
  gpor_token_hash VARCHAR(512) NOT NULL,
  gpor_jti VARCHAR(128),
  gpor_enabled SMALLINT DEFAULT 1,
  FOREIGN KEY(gpoc_id) REFERENCES gpo_code(gpoc_id) ON DELETE CASCADE
);
CREATE INDEX i_gpor_token_hash ON gpo_refresh_token(gpor_token_hash);
CREATE INDEX i_gpor_jti ON gpo_refresh_token(gpor_jti);

CREATE TABLE gpo_refresh_token_scope (
  gpors_id SERIAL PRIMARY KEY,
  gpor_id INTEGER,
  gpors_scope VARCHAR(128) NOT NULL,
  FOREIGN KEY(gpor_id) REFERENCES gpo_refresh_token(gpor_id) ON DELETE CASCADE
);

-- Access token table, to store meta information on access token sent
CREATE TABLE gpo_access_token (
  gpoa_id SERIAL PRIMARY KEY,
  gpoa_plugin_name VARCHAR(256) NOT NULL,
  gpoa_authorization_type SMALLINT NOT NULL,
  gpor_id INTEGER DEFAULT NULL,
  gpoa_username VARCHAR(256),
  gpoa_client_id VARCHAR(256),
  gpoa_issued_at TIMESTAMPTZ DEFAULT NOW(),
  gpoa_issued_for VARCHAR(256), -- IP address or hostname
  gpoa_user_agent VARCHAR(256),
  gpoa_token_hash VARCHAR(512) NOT NULL,
  gpoa_jti VARCHAR(128),
  gpoa_enabled SMALLINT DEFAULT 1,
  FOREIGN KEY(gpor_id) REFERENCES gpo_refresh_token(gpor_id) ON DELETE CASCADE
);
CREATE INDEX i_gpoa_token_hash ON gpo_access_token(gpoa_token_hash);
CREATE INDEX i_gpoa_jti ON gpo_access_token(gpoa_jti);

CREATE TABLE gpo_access_token_scope (
  gpoas_id SERIAL PRIMARY KEY,
  gpoa_id INTEGER,
  gpoas_scope VARCHAR(128) NOT NULL,
  FOREIGN KEY(gpoa_id) REFERENCES gpo_access_token(gpoa_id) ON DELETE CASCADE
);

-- Id token table, to store meta information on id token sent
CREATE TABLE gpo_id_token (
  gpoi_id SERIAL PRIMARY KEY,
  gpoi_plugin_name VARCHAR(256) NOT NULL,
  gpoi_authorization_type SMALLINT NOT NULL,
  gpoi_username VARCHAR(256),
  gpoi_client_id VARCHAR(256),
  gpoi_issued_at TIMESTAMPTZ DEFAULT NOW(),
  gpoi_issued_for VARCHAR(256), -- IP address or hostname
  gpoi_user_agent VARCHAR(256),
  gpoi_hash VARCHAR(512),
  gpoi_enabled SMALLINT DEFAULT 1
);
CREATE INDEX i_gpoi_hash ON gpo_id_token(gpoi_hash);

-- subject identifier table to store subs and their relations to usernames, client_id and sector_identifier
CREATE TABLE gpo_subject_identifier (
  gposi_id SERIAL PRIMARY KEY,
  gposi_plugin_name VARCHAR(256) NOT NULL,
  gposi_username VARCHAR(256) NOT NULL,
  gposi_client_id VARCHAR(256),
  gposi_sector_identifier_uri VARCHAR(256),
  gposi_sub VARCHAR(256) NOT NULL
);
CREATE INDEX i_gposi_sub ON gpo_subject_identifier(gposi_sub);

-- store meta information on client registration
CREATE TABLE gpo_client_registration (
  gpocr_id SERIAL PRIMARY KEY,
  gpocr_plugin_name VARCHAR(256) NOT NULL,
  gpocr_cient_id VARCHAR(256) NOT NULL,
  gpocr_management_at_hash VARCHAR(512),
  gpocr_created_at TIMESTAMPTZ DEFAULT NOW(),
  gpoa_id INTEGER,
  gpocr_issued_for VARCHAR(256), -- IP address or hostname
  gpocr_user_agent VARCHAR(256),
  FOREIGN KEY(gpoa_id) REFERENCES gpo_access_token(gpoa_id) ON DELETE CASCADE
);
CREATE INDEX i_gpocr_management_at_hash ON gpo_client_registration(gpocr_management_at_hash);

-- store meta information about client request on token endpoint
CREATE TABLE gpo_client_token_request (
  gpoctr_id SERIAL PRIMARY KEY,
  gpoctr_plugin_name VARCHAR(256) NOT NULL,
  gpoctr_cient_id VARCHAR(256) NOT NULL,
  gpoctr_created_at TIMESTAMPTZ DEFAULT NOW(),
  gpoctr_issued_for VARCHAR(256), -- IP address or hostname
  gpoctr_jti_hash VARCHAR(512)
);

-- store device authorization requests
CREATE TABLE gpo_device_authorization (
  gpoda_id SERIAL PRIMARY KEY,
  gpoda_plugin_name VARCHAR(256) NOT NULL,
  gpoda_client_id VARCHAR(256) NOT NULL,
  gpoda_username VARCHAR(256),
  gpoda_created_at TIMESTAMPTZ DEFAULT NOW(),
  gpoda_expires_at TIMESTAMPTZ DEFAULT NOW(),
  gpoda_issued_for VARCHAR(256), -- IP address or hostname of the deice client
  gpoda_device_code_hash VARCHAR(512) NOT NULL,
  gpoda_user_code_hash VARCHAR(512) NOT NULL,
  gpoda_status SMALLINT DEFAULT 0, -- 0: created, 1: user verified, 2 device completed, 3 disabled
  gpoda_last_check TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX i_gpoda_device_code_hash ON gpo_device_authorization(gpoda_device_code_hash);
CREATE INDEX i_gpoda_user_code_hash ON gpo_device_authorization(gpoda_user_code_hash);

CREATE TABLE gpo_device_authorization_scope (
  gpodas_id SERIAL PRIMARY KEY,
  gpoda_id INTEGER,
  gpodas_scope VARCHAR(128) NOT NULL,
  gpodas_allowed SMALLINT DEFAULT 0,
  FOREIGN KEY(gpoda_id) REFERENCES gpo_device_authorization(gpoda_id) ON DELETE CASCADE
);

CREATE TABLE gpo_device_scheme (
  gpodh_id SERIAL PRIMARY KEY,
  gpoda_id INTEGER,
  gpodh_scheme_module VARCHAR(128) NOT NULL,
  FOREIGN KEY(gpoda_id) REFERENCES gpo_device_authorization(gpoda_id) ON DELETE CASCADE
);
