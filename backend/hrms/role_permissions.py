"""Single source of truth for HRMS role/module/action permissions."""

ACTIONS = ('view', 'create', 'edit', 'approve', 'publish', 'administer')

ROLE_PERMISSIONS = {
    'employee': {
        'profile': {'view', 'edit'},
        'attendance': {'view', 'create'},
        'leave': {'view', 'create'},
        'tasks': {'view', 'edit'},
        'documents': {'view', 'create'},
        'meetings': {'view'},
        'payroll': {'view'},
        'performance': {'view', 'edit'},
        'notifications': {'view', 'edit'},
    },
    'tl': {
        'profile': {'view', 'edit'},
        'employees': {'view'},
        'attendance': {'view', 'approve'},
        'leave': {'view', 'approve'},
        'tasks': {'view', 'create', 'edit', 'approve'},
        'meetings': {'view', 'create', 'edit'},
        'performance': {'view', 'edit', 'approve'},
        'approvals': {'view', 'approve'},
        'notifications': {'view', 'edit'},
        'reports': {'view'},
    },
    'hr': {
        'profile': {'view', 'edit'},
        'employees': {'view', 'create', 'edit'},
        'attendance': {'view', 'edit', 'approve'},
        'leave': {'view', 'edit', 'approve', 'administer'},
        'tasks': {'view', 'create', 'edit'},
        'documents': {'view', 'edit', 'approve'},
        'meetings': {'view', 'create', 'edit'},
        'recruitment': {'view', 'create', 'edit', 'approve'},
        'onboarding': {'view', 'create', 'edit', 'approve'},
        'training': {'view', 'create', 'edit'},
        'performance': {'view', 'create', 'edit', 'approve'},
        'payroll': {'view', 'create', 'edit', 'publish'},
        'notifications': {'view', 'create', 'edit'},
        'reports': {'view', 'create'},
    },
    'finance': {
        'profile': {'view', 'edit'},
        'employees': {'view'},
        'attendance': {'view'},
        'leave': {'view'},
        'payroll': {'view', 'edit', 'approve'},
        'reports': {'view', 'create'},
        'notifications': {'view', 'edit'},
    },
    'ceo': {
        'profile': {'view', 'edit'},
        'employees': {'view'},
        'attendance': {'view', 'approve'},
        'leave': {'view', 'approve', 'administer'},
        'tasks': {'view'},
        'documents': {'view'},
        'meetings': {'view', 'create', 'edit'},
        'recruitment': {'view', 'create', 'edit', 'approve'},
        'performance': {'view', 'approve'},
        'payroll': {'view', 'approve'},
        'approvals': {'view', 'approve'},
        'reports': {'view', 'create'},
        'notifications': {'view', 'edit'},
        'organization': {'view', 'edit', 'approve'},
    },
    'md': {
        'profile': {'view', 'edit'},
        'employees': {'view'},
        'attendance': {'view'},
        'leave': {'view'},
        'tasks': {'view'},
        'documents': {'view'},
        'meetings': {'view', 'create', 'edit'},
        'recruitment': {'view'},
        'performance': {'view'},
        'payroll': {'view'},
        'approvals': {'view'},
        'reports': {'view'},
        'notifications': {'view', 'edit'},
        'organization': {'view'},
    },
    'director': {},
    'admin': {
        'profile': {'view', 'edit'},
        'employees': {'view', 'create', 'edit', 'administer'},
        'attendance': {'view', 'edit'},
        'leave': {'view', 'edit'},
        'tasks': {'view', 'create', 'edit', 'administer'},
        'documents': {'view', 'edit', 'administer'},
        'meetings': {'view', 'create', 'edit', 'administer'},
        'recruitment': {'view', 'administer'},
        'performance': {'view', 'administer'},
        'payroll': {'view', 'administer'},
        'reports': {'view', 'create', 'administer'},
        'notifications': {'view', 'create', 'edit', 'administer'},
        'settings': {'view', 'edit', 'administer'},
    },
    'marketing': {
        'profile': {'view', 'edit'},
        'tasks': {'view', 'edit'},
        'approvals': {'view', 'create'},
        'meetings': {'view'},
        'notifications': {'view', 'edit'},
    },
    'it': {
        'profile': {'view', 'edit'},
        'employees': {'view'},
        'tasks': {'view', 'edit'},
        'assets': {'view', 'create', 'edit', 'administer'},
        'documents': {'view'},
        'notifications': {'view', 'edit'},
        'settings': {'view', 'edit'},
    },
}

# Directors have the same read-oriented executive scope as MD.
ROLE_PERMISSIONS['director'] = {
    module: set(actions) for module, actions in ROLE_PERMISSIONS['md'].items()
}


def has_permission(role, module, action):
    role = str(role or '').strip().lower()
    module = str(module or '').strip().lower()
    action = str(action or '').strip().lower()
    if role == 'superadmin':
        return module != '' and action in ACTIONS
    return action in ROLE_PERMISSIONS.get(role, {}).get(module, set())


def permissions_for_role(role):
    role = str(role or '').strip().lower()
    if role == 'superadmin':
        return {'*': list(ACTIONS)}
    return {
        module: sorted(actions, key=ACTIONS.index)
        for module, actions in ROLE_PERMISSIONS.get(role, {}).items()
    }
