/*
 * Minimal stand-in for <mach/coalition.h> (xnu-8020.101.4).
 * The iOS SDK does not ship this kernel header, but both
 * <sys/spawn_internal.h> and <sys/proc_info.h> need the constants
 * below to size their structs correctly.
 */
#ifndef _MACH_COALITION_H_
#define _MACH_COALITION_H_

#include <stdint.h>

#define COALITION_TYPE_RESOURCE  (0)
#define COALITION_TYPE_JETSAM    (1)
#define COALITION_TYPE_MAX       (1)

#define COALITION_NUM_TYPES      (COALITION_TYPE_MAX + 1)

typedef uint64_t coalition_id_t;

#endif /* _MACH_COALITION_H_ */
