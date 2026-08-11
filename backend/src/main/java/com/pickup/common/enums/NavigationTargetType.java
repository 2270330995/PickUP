package com.pickup.common.enums;

/**
 * Computed navigation target for a trip read model. Not persisted — derived from
 * trip status and current execution step at map time.
 */
public enum NavigationTargetType {
    NONE,
    CURRENT_STOP,
    FINAL_DESTINATION
}
