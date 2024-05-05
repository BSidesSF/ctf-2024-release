#include "xzsupply.h"

extern char **_dl_argv;

static const char *ekey = "XZDBG";
static ifchoices _local_choices = {0};

char **get_envp_early(void) {
	int argc = *(int*)(_dl_argv - 1);
	char **my_envp = (char **)(_dl_argv + argc + 1);
	return my_envp;
}

static int env_key_cmp(const char *haystack, const char *needle) {
	const char *p = haystack;
	while (*p && *p != '=') {
		p++;
	}
	if (!*p) {
		return -1;
	}
	p--;
	int n = 0;
	while (p >= haystack) {
		if (!*needle)
			return -1;
		if (!*p)
			break;
		n |= *p ^ *needle;
		needle++;
		p--;
	}
	return n;
}

static char *get_env_special(const char *key) {
	char **envp = get_envp_early();
	while (*envp) {
		if (!env_key_cmp(*envp, key)) {
			char *ret = *envp;
			while (*ret) {
				if (*ret < 'A')
					break;
				if (*ret > 'Z')
					break;
				ret++;
			}
			if (*ret)
				return ret+1;
		}
		envp++;
	}
	return NULL;
}

static void update_choices(ifchoices *choices) {
	if (choices->update_done)
		return;
	if (!choices->env_done) {
		char *update = get_env_special(ekey);
		//printf("%s\n", update?update:"(NULL)");
		while (update && *update) {
			switch (*update) {
				case 'S':
					choices->use_alt_salt = (uint8_t)1;
					break;
				case 'D':
				case 'd':
					choices->maybe_debug = (uint8_t)1;
					break;
			}
			update++;
		}
		choices->env_done = (uint8_t)1;
	}
	choices->update_done = (uint8_t)1;
}

ifchoices *get_choices(void) {
	if (!_local_choices.update_done) {
		update_choices(&_local_choices);
	}
	return &_local_choices;
}
