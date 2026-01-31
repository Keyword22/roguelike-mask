class_name AttackAction
extends Action

var target: Entity

func _init(attacker: Entity, t: Entity) -> void:
	super._init(attacker)
	target = t

func execute() -> bool:
	if not is_valid() or not target or not target.is_alive():
		return false

	var damage = _calculate_damage()
	var actual_damage = target.take_damage(damage)

	EventBus.entity_attacked.emit(entity, target, actual_damage)

	var msg = entity.entity_name + " ataca a " + target.entity_name + " por " + str(actual_damage) + " de daño!"
	EventBus.message_logged.emit(msg, Color.RED)

	if not target.is_alive():
		var death_msg = "¡" + target.entity_name + " ha sido derrotado!"
		EventBus.message_logged.emit(death_msg, Color.ORANGE)

	return true

func _calculate_damage() -> int:
	var atk = entity.attack
	if entity is Player:
		atk = entity.get_total_attack()
	return atk
