use serde::Serialize;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize)]
pub struct TaskNotification {
    pub task_id: Uuid,
    pub result: serde_json::Value,
}
