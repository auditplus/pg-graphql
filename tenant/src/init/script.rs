use std::cmp::Ordering;
use std::path::Path;
use std::{fs, io};

#[derive(Debug)]
pub struct Script {
    pub prefix: u32,
    pub name: String,
    pub stmts: Vec<String>,
}

impl PartialEq for Script {
    fn eq(&self, other: &Self) -> bool {
        self.prefix == other.prefix
    }
}

impl Eq for Script {}

impl Ord for Script {
    fn cmp(&self, other: &Self) -> Ordering {
        self.prefix.cmp(&other.prefix)
    }
}

impl PartialOrd for Script {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl IntoIterator for Script {
    type Item = String;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.stmts.into_iter()
    }
}

pub struct Scripts(Vec<Script>);

impl Scripts {
    pub fn from_dir<P>(path: P) -> io::Result<Scripts>
    where
        P: AsRef<Path>,
    {
        let dirs = fs::read_dir(path)?;
        let mut scripts = Vec::new();
        for dir in dirs.flatten() {
            let file_name = dir.file_name().to_string_lossy().to_string();
            let (x, y) = file_name.split_at(4);
            let stmts = fs::read_to_string(dir.path())?
                .split("--##")
                .map(|x| x.to_string())
                .collect();
            let prefix = x
                .trim_end_matches("_")
                .parse::<u32>()
                .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e.to_string()))?;
            scripts.push(Script {
                stmts,
                name: y.to_string(),
                prefix,
            });
            scripts.sort();
        }
        Ok(Scripts(scripts))
    }
}

impl IntoIterator for Scripts {
    type Item = Script;
    type IntoIter = std::vec::IntoIter<Self::Item>;

    fn into_iter(self) -> Self::IntoIter {
        self.0.into_iter()
    }
}
