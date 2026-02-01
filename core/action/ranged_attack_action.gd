class_name RangedAttackAction
extends Action

var target: Entity
var damage_bonus: int = 0

func _init(attacker: Entity, t: Entity, bonus: int = 0) -> void:
	super._init(attacker)
	target = t
	damage_bonus = bonus

func execute() -> bool:
	if not is_valid() or not target or not target.is_alive():
		return false

	var damage = entity.attack + damage_bonus
	var actual_damage = target.take_damage(damage)

	EventBus.entity_ranged_attack.emit(entity, target, actual_damage)

	if not target.is_alive():
		EventBus.message_logged.emit("¡" + target.entity_name + " ha sido derrotado!", Color.ORANGE)

	return true
