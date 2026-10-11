// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
// Round 0 synthetic librime acceptance. No IMK client, UI, sync, or cleanup.
// Engine-managed maintenance is permitted only in LiangYi's own data/log roots.

#include "rime_api.h"

#include <errno.h>
#include <fts.h>
#include <limits.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

enum { kCycles = 10, kEscape = 0xff1b, kCandidateCapacity = 512 };

typedef struct {
  int completed_cycles;
  int space_passes;
  int numeric_passes;
  int escape_passes;
  bool roots_preflight;
  bool roots_postflight;
  bool maintenance_started;
  bool deployment_failure;
  bool finalized;
  const char *error;
} SmokeResult;

static bool fail(SmokeResult *result, const char *code) {
  if (result->error == NULL) {
    result->error = code;
    fprintf(stderr, "Rime smoke check failed: %s\n", code);
  }
  return false;
}

static bool append_path(char *output, size_t size, const char *base,
                        const char *suffix) {
  int length = snprintf(output, size, "%s/%s", base, suffix);
  return length >= 0 && (size_t)length < size;
}

static bool is_within(const char *path, const char *root) {
  size_t length = strlen(root);
  return strncmp(path, root, length) == 0 &&
         (path[length] == '\0' || path[length] == '/');
}

// Check every existing ancestor with lstat. Never follow a directory symlink,
// including one in the home, Library, data-root, or log-root paths.
static bool check_ancestors(const char *path, bool require_final_directory) {
  char prefix[PATH_MAX];
  size_t length = strlen(path);
  if (length < 2 || length >= sizeof(prefix) || path[0] != '/') {
    return false;
  }
  memcpy(prefix, path, length + 1);
  for (size_t index = 1; index <= length; ++index) {
    if (index < length && prefix[index] != '/') {
      continue;
    }
    if (index > 1 && prefix[index - 1] == '/') {
      return false;
    }
    char saved = prefix[index];
    prefix[index] = '\0';
    const char *component = strrchr(prefix, '/');
    component = component != NULL ? component + 1 : prefix;
    if (strcmp(component, ".") == 0 || strcmp(component, "..") == 0 ||
        component[0] == '\0') {
      return false;
    }
    struct stat metadata;
    if (lstat(prefix, &metadata) == 0) {
      if (S_ISLNK(metadata.st_mode) || !S_ISDIR(metadata.st_mode)) {
        return false;
      }
    } else if (errno != ENOENT || require_final_directory) {
      return false;
    }
    prefix[index] = saved;
  }
  return true;
}

// Create missing ordinary directories only. No replacement, chmod, unlink,
// rename, or deletion is performed; all existing ancestors were inspected.
static bool create_directories(const char *path) {
  if (!check_ancestors(path, false)) {
    return false;
  }
  char prefix[PATH_MAX];
  size_t length = strlen(path);
  if (length >= sizeof(prefix)) {
    return false;
  }
  memcpy(prefix, path, length + 1);
  for (size_t index = 1; index <= length; ++index) {
    if (index < length && prefix[index] != '/') {
      continue;
    }
    char saved = prefix[index];
    prefix[index] = '\0';
    struct stat metadata;
    if (lstat(prefix, &metadata) != 0) {
      if (errno != ENOENT || mkdir(prefix, 0700) != 0) {
        return false;
      }
      if (lstat(prefix, &metadata) != 0) {
        return false;
      }
    }
    if (S_ISLNK(metadata.st_mode) || !S_ISDIR(metadata.st_mode)) {
      return false;
    }
    prefix[index] = saved;
  }
  return true;
}

// librime/glog can create in-root file symlinks. Permit only fully resolved
// targets within the same root; dangling or escaping links fail closed.
// Physical traversal does not follow directory links or read file contents.
static bool check_root_tree(const char *root) {
  if (!check_ancestors(root, true)) {
    return false;
  }
  char canonical[PATH_MAX];
  if (realpath(root, canonical) == NULL || strcmp(root, canonical) != 0) {
    return false;
  }
  char *paths[] = {(char *)root, NULL};
  FTS *tree = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
  if (tree == NULL) {
    return false;
  }
  bool valid = true;
  FTSENT *entry;
  errno = 0;
  while ((entry = fts_read(tree)) != NULL) {
    if (entry->fts_info == FTS_SL || entry->fts_info == FTS_SLNONE) {
      char target[PATH_MAX];
      if (realpath(entry->fts_path, target) == NULL ||
          !is_within(target, canonical)) {
        valid = false;
        break;
      }
    } else if (entry->fts_info == FTS_DNR || entry->fts_info == FTS_ERR ||
               entry->fts_info == FTS_NS) {
      valid = false;
      break;
    }
    errno = 0;
  }
  if (entry == NULL && errno != 0) {
    valid = false;
  }
  if (fts_close(tree) != 0) {
    valid = false;
  }
  return valid;
}

static void deployment_notification(void *context, RimeSessionId session,
                                    const char *type, const char *value) {
  (void)session;
  SmokeResult *result = context;
  if (type != NULL && value != NULL && strcmp(type, "deploy") == 0 &&
      strcmp(value, "failure") == 0) {
    result->deployment_failure = true;
  }
}

static bool required_api(RimeApi *api) {
  return api != NULL && RIME_API_AVAILABLE(api, setup) &&
         RIME_API_AVAILABLE(api, set_notification_handler) &&
         RIME_API_AVAILABLE(api, initialize) &&
         RIME_API_AVAILABLE(api, finalize) &&
         RIME_API_AVAILABLE(api, start_maintenance) &&
         RIME_API_AVAILABLE(api, join_maintenance_thread) &&
         RIME_API_AVAILABLE(api, create_session) &&
         RIME_API_AVAILABLE(api, destroy_session) &&
         RIME_API_AVAILABLE(api, select_schema) &&
         RIME_API_AVAILABLE(api, get_current_schema) &&
         RIME_API_AVAILABLE(api, set_option) &&
         RIME_API_AVAILABLE(api, get_option) &&
         RIME_API_AVAILABLE(api, process_key) &&
         RIME_API_AVAILABLE(api, clear_composition) &&
         RIME_API_AVAILABLE(api, get_context) &&
         RIME_API_AVAILABLE(api, free_context) &&
         RIME_API_AVAILABLE(api, get_commit) &&
         RIME_API_AVAILABLE(api, free_commit) &&
         RIME_API_AVAILABLE(api, get_status) &&
         RIME_API_AVAILABLE(api, free_status) &&
         RIME_API_AVAILABLE(api, get_input);
}

static bool no_commit(RimeApi *api, RimeSessionId session,
                      SmokeResult *result) {
  RIME_STRUCT(RimeCommit, commit);
  if (!api->get_commit(session, &commit)) {
    return true;
  }
  bool released = api->free_commit(&commit) != False;
  return fail(result, released ? "unexpected_commit" : "free_commit_failed");
}

static bool empty_composition(RimeApi *api, RimeSessionId session,
                              SmokeResult *result) {
  RIME_STRUCT(RimeContext, context);
  if (!api->get_context(session, &context)) {
    return fail(result, "empty_context_unavailable");
  }
  bool empty = context.composition.length == 0 &&
               (context.composition.preedit == NULL ||
                context.composition.preedit[0] == '\0') &&
               context.menu.num_candidates == 0;
  bool released = api->free_context(&context) != False;
  if (!released) {
    return fail(result, "free_context_failed");
  }
  const char *input = api->get_input(session);
  if (!empty || input == NULL || input[0] != '\0') {
    return fail(result, "composition_not_empty");
  }
  return no_commit(api, session, result);
}

static bool clear_and_check(RimeApi *api, RimeSessionId session,
                            SmokeResult *result) {
  // clear_composition returns void. Verify both context and unread commits;
  // never treat clearing as an acknowledgment that the state was reset.
  api->clear_composition(session);
  return empty_composition(api, session, result);
}

static bool type_synthetic(RimeApi *api, RimeSessionId session,
                           const char *literal, SmokeResult *result) {
  for (const unsigned char *key = (const unsigned char *)literal; *key; ++key) {
    if (!api->process_key(session, *key, 0)) {
      return fail(result, "synthetic_key_unhandled");
    }
  }
  return no_commit(api, session, result);
}

static bool first_candidate(RimeApi *api, RimeSessionId session,
                            char *copy, size_t size, bool numeric,
                            SmokeResult *result) {
  RIME_STRUCT(RimeContext, context);
  if (!api->get_context(session, &context)) {
    return fail(result, "candidate_context_unavailable");
  }
  bool available = context.composition.length > 0 &&
                   context.menu.num_candidates > 0 &&
                   context.menu.candidates != NULL &&
                   context.menu.candidates[0].text != NULL;
  if (available) {
    const char *text = context.menu.candidates[0].text;
    size_t length = strnlen(text, size);
    available = length > 0 && length < size;
    if (available) {
      memcpy(copy, text, length + 1);
    }
  }
  // The fixed baseline's default numeric selection labels start at 1.
  if (numeric && context.menu.select_keys != NULL &&
      context.menu.select_keys[0] != '1') {
    available = false;
  }
  bool released = api->free_context(&context) != False;
  if (!released) {
    return fail(result, "free_context_failed");
  }
  return available || fail(result, "first_candidate_unavailable");
}

static bool exact_commit(RimeApi *api, RimeSessionId session,
                         const char *expected, SmokeResult *result) {
  RIME_STRUCT(RimeCommit, commit);
  if (!api->get_commit(session, &commit)) {
    return fail(result, "commit_unavailable");
  }
  bool matches = commit.text != NULL && strcmp(commit.text, expected) == 0;
  bool released = api->free_commit(&commit) != False;
  if (!released) {
    return fail(result, "free_commit_failed");
  }
  if (!matches) {
    return fail(result, "commit_mismatch");
  }
  // A second unread commit or leftover input is a failed at-most-once check.
  return empty_composition(api, session, result);
}

static bool run_cycle(RimeApi *api, RimeSessionId session,
                      SmokeResult *result) {
  char candidate[kCandidateCapacity];
  if (!clear_and_check(api, session, result) ||
      !type_synthetic(api, session, "nihao", result) ||
      !first_candidate(api, session, candidate, sizeof(candidate), false,
                       result)) {
    return false;
  }
  if (strcmp(candidate, "你好") != 0) {
    return fail(result, "nihao_first_candidate_mismatch");
  }
  if (!api->process_key(session, ' ', 0)) {
    return fail(result, "space_unhandled");
  }
  if (!exact_commit(api, session, "你好", result)) {
    return false;
  }
  ++result->space_passes;

  if (!clear_and_check(api, session, result) ||
      !type_synthetic(api, session, "zhongguo", result) ||
      !first_candidate(api, session, candidate, sizeof(candidate), true,
                       result)) {
    return false;
  }
  if (!api->process_key(session, '1', 0)) {
    return fail(result, "numeric_selection_unhandled");
  }
  if (!exact_commit(api, session, candidate, result)) {
    return false;
  }
  ++result->numeric_passes;

  if (!clear_and_check(api, session, result) ||
      !type_synthetic(api, session, "nihao", result) ||
      !first_candidate(api, session, candidate, sizeof(candidate), false,
                       result)) {
    return false;
  }
  // librime uses X11 key symbols; 0xff1b is Escape, not an ASCII byte.
  if (!api->process_key(session, kEscape, 0)) {
    return fail(result, "escape_unhandled");
  }
  if (!empty_composition(api, session, result)) {
    return false;
  }
  ++result->escape_passes;
  ++result->completed_cycles;
  return true;
}

static void emit_result(const SmokeResult *result) {
  printf("{\n"
         "  \"schema_version\": 1,\n"
         "  \"scope\": \"real librime only; no IMK client/UI\",\n"
         "  \"status\": \"%s\",\n"
         "  \"cycles_requested\": %d,\n"
         "  \"cycles_completed\": %d,\n"
         "  \"cases\": {\n"
         "    \"nihao_space_exact_commit\": %d,\n"
         "    \"zhongguo_numeric_matches_displayed_first\": %d,\n"
         "    \"escape_clears_without_commit\": %d\n"
         "  },\n"
         "  \"roots_preflight_passed\": %s,\n"
         "  \"roots_postflight_passed\": %s,\n"
         "  \"maintenance_started\": %s,\n"
         "  \"deployment_failure_observed\": %s,\n"
         "  \"finalized\": %s,\n"
         "  \"document_text_read\": false,\n"
         "  \"network_requests\": false,\n"
         "  \"manual_cleanup_performed\": false,\n"
         "  \"error\": ",
         result->error == NULL ? "PASS" : "FAIL", kCycles,
         result->completed_cycles, result->space_passes,
         result->numeric_passes, result->escape_passes,
         result->roots_preflight ? "true" : "false",
         result->roots_postflight ? "true" : "false",
         result->maintenance_started ? "true" : "false",
         result->deployment_failure ? "true" : "false",
         result->finalized ? "true" : "false");
  if (result->error == NULL) {
    puts("null\n}");
  } else {
    // Error codes are fixed literals; no paths, candidates, or logs are output.
    printf("\"%s\"\n}\n", result->error);
  }
}

int main(int argc, char **argv) {
  SmokeResult result = {0};
  RimeApi *api = NULL;
  RimeSessionId session = 0;
  bool initialized = false;
  char data_root[PATH_MAX];
  char log_root[PATH_MAX];
  char staging[PATH_MAX];
  char prebuilt[PATH_MAX];
  char shared[PATH_MAX];

  if (argc != 2) {
    fail(&result, "usage_shared_support_path_required");
    goto finished;
  }
  struct passwd *account = getpwuid(geteuid());
  // HOME is deliberately ignored: a caller cannot redirect writable roots.
  if (account == NULL || account->pw_dir == NULL ||
      !check_ancestors(account->pw_dir, true)) {
    fail(&result, "account_home_unavailable_or_unsafe");
    goto finished;
  }
  if (!append_path(data_root, sizeof(data_root), account->pw_dir,
                   "Library/Application Support/LiangYi/Rime") ||
      !append_path(log_root, sizeof(log_root), account->pw_dir,
                   "Library/Logs/LiangYi") ||
      !append_path(staging, sizeof(staging), data_root, "build") ||
      !append_path(prebuilt, sizeof(prebuilt), argv[1], "build")) {
    fail(&result, "path_too_long");
    goto finished;
  }
  if (!check_ancestors(argv[1], true) ||
      realpath(argv[1], shared) == NULL || strcmp(argv[1], shared) != 0) {
    fail(&result, "shared_support_path_unsafe");
    goto finished;
  }
  if (!create_directories(data_root) || !create_directories(log_root) ||
      !create_directories(staging) || !check_root_tree(data_root) ||
      !check_root_tree(log_root)) {
    fail(&result, "writable_root_preflight_failed");
    goto finished;
  }
  result.roots_preflight = true;
  api = rime_get_api();
  if (!required_api(api)) {
    fail(&result, "required_rime_api_unavailable");
    goto finished;
  }

  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir = shared;
  traits.user_data_dir = data_root;
  traits.log_dir = log_root;
  traits.prebuilt_data_dir = prebuilt;
  traits.staging_dir = staging;
  traits.distribution_name = "LiangYi Round 0 engine smoke";
  traits.distribution_code_name = "EcholME";
  traits.distribution_version = "0.0.1";
  traits.app_name = "liangyi.echolme-smoke";
  traits.min_log_level = 2;
  api->setup(&traits);
  api->set_notification_handler(deployment_notification, &result);
  api->initialize(NULL);
  initialized = true;
  result.maintenance_started = api->start_maintenance(False) != False;
  // A false return means no maintenance was scheduled, not an API error.
  api->join_maintenance_thread();
  if (result.deployment_failure) {
    fail(&result, "deployment_failure_notification");
    goto finished;
  }
  session = api->create_session();
  if (session == 0 || !api->select_schema(session, "luna_pinyin_simp")) {
    fail(&result, "schema_selection_failed");
    goto finished;
  }
  char schema[128];
  if (!api->get_current_schema(session, schema, sizeof(schema)) ||
      strcmp(schema, "luna_pinyin_simp") != 0) {
    fail(&result, "selected_schema_mismatch");
    goto finished;
  }
  api->set_option(session, "ascii_mode", False);
  RIME_STRUCT(RimeStatus, status);
  if (!api->get_status(session, &status)) {
    fail(&result, "schema_status_unavailable");
    goto finished;
  }
  bool chinese = !status.is_disabled && !status.is_ascii_mode &&
                 !api->get_option(session, "ascii_mode");
  if (!api->free_status(&status)) {
    fail(&result, "free_status_failed");
    goto finished;
  }
  if (!chinese) {
    fail(&result, "chinese_mode_unavailable");
    goto finished;
  }
  for (int cycle = 0; cycle < kCycles; ++cycle) {
    if (!run_cycle(api, session, &result)) {
      break;
    }
  }

finished:
  if (session != 0 && api != NULL && !api->destroy_session(session)) {
    fail(&result, "destroy_session_failed");
  }
  if (initialized) {
    api->finalize();
    result.finalized = true;
    result.roots_postflight =
        check_root_tree(data_root) && check_root_tree(log_root);
    if (!result.roots_postflight) {
      fail(&result, "writable_root_postflight_failed");
    }
  }
  if (result.error == NULL && result.completed_cycles != kCycles) {
    fail(&result, "incomplete_cycles");
  }
  emit_result(&result);
  return result.error == NULL ? EXIT_SUCCESS : EXIT_FAILURE;
}
