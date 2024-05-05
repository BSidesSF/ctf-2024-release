#ifndef __AI_H__
#define __AI_H__

typedef enum {
  AI_RANDOM, // Ironclad
  AI_CHEATER, // Silent
  AI_SMART, // Defect
  AI_SEQUENTIAL, // Watcher
} ai_t;

extern char *ai_names[];
extern char *ai_descriptions[];

#endif
