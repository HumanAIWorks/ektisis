# Ektisis

[English](./README.md)

Ektisis transforma intenção humana em software funcional com assistência de IA.

## Foco atual

O projeto começa pela Fase 0: scripts que preparam e validam uma máquina Linux para que ela possa se comportar como um servidor confiável.

## Sistemas suportados

- Debian 12+ server/minimal
- Ubuntu Server LTS

Recomendação:

- Debian 12+ para máquina local dedicada
- Ubuntu Server LTS para VPS/cloud

## Começar em uma máquina nova

Rode primeiro em uma máquina Debian ou Ubuntu recém-criada:

```bash
sudo apt-get update
sudo apt-get install -y git

git clone https://github.com/HumanAIWorks/ektisis.git
cd ektisis
```

Depois rode a Fase 0:

```bash
bash phases/phase-0/doctor.sh
sudo bash phases/phase-0/bootstrap.sh
bash phases/phase-0/validate.sh
bash phases/phase-0/generate-machine-md.sh
```

Se o Docker for instalado pela primeira vez, pode ser necessário sair e entrar novamente na sessão antes da validação.

## Princípio

Começar com a menor base possível. Adicionar apenas o necessário para deixar a máquina pronta para a próxima fase.
