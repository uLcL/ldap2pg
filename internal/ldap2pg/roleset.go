package ldap2pg

type RoleSet map[string]Role

func (roles RoleSet) Diff(wanted RoleSet) (diff []interface{}) {
	return
}
